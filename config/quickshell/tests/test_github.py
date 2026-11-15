from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

spec = importlib.util.spec_from_file_location('github_commits', Path(__file__).resolve().parents[1] / 'scripts/github-commits.py')
github = importlib.util.module_from_spec(spec)
spec.loader.exec_module(github)


class GitHubTracker(unittest.TestCase):
    def test_totals_use_search_count_not_page_size(self):
        responses = [{'total_count': 12, 'items': []}]
        with patch.object(github, 'search', side_effect=responses) as search, patch.object(github, 'calendar', return_value=[]):
            result = github.fetch('SAB1825', datetime(2026, 1, 2, tzinfo=timezone.utc))
        self.assertEqual(result['today'], 12)
        search.assert_called_once_with('SAB1825', '2026-01-02')

    def test_recent_links_and_first_message_line(self):
        item = {'html_url': 'https://github.com/SAB1825/test/commit/abc',
                'sha': 'abcdef12345', 'commit': {'message': 'Fix clock\n\nDetails'},
                'repository': {'full_name': 'SAB1825/test'}}
        invalid = {**item, 'html_url': 'https://example.com/untrusted'}
        with patch.object(github, 'search', return_value={'total_count': 1, 'items': [item, invalid]}), patch.object(github, 'calendar', return_value=[]):
            result = github.fetch('SAB1825')
        self.assertEqual(len(result['recent']), 1)
        self.assertEqual(result['recent'][0]['title'], 'Fix clock')
        self.assertEqual(result['recent'][0]['sha'], 'abcdef1')

    def test_cache_and_rate_limit_preserve_count(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(github.os.environ, {'XDG_CACHE_HOME': directory}):
            data = {'username': 'SAB1825', 'date': datetime.now(timezone.utc).date().isoformat(),
                    'schema': github.SCHEMA, 'today': 3, 'recent': [], 'updated': 'now', 'error': '', 'stale': False}
            with patch.object(github, 'fetch', return_value=data) as fetch:
                github.tracker('SAB1825')
                self.assertEqual(github.tracker('SAB1825')['today'], 3)
                fetch.assert_called_once()
            path = Path(directory) / 'phoenix/github-SAB1825.json'
            cached = json.loads(path.read_text())
            cached['attempted'] = 0
            path.write_text(json.dumps(cached))
            with patch.object(github, 'fetch', side_effect=HTTPError('url', 403, 'limited', {}, None)):
                result = github.tracker('SAB1825', True)
            self.assertEqual(result['today'], 3)
            self.assertTrue(result['stale'])
            self.assertIn('rate limit', result['error'])

    def test_previous_day_cache_is_not_shown_as_today(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(github.os.environ, {'XDG_CACHE_HOME': directory}):
            path = Path(directory) / 'phoenix/github-SAB1825.json'
            path.parent.mkdir()
            path.write_text(json.dumps({'schema': github.SCHEMA, 'date': '2000-01-01', 'today': 50, 'attempted': 0}))
            with patch.object(github, 'fetch', side_effect=OSError('offline')):
                result = github.tracker('SAB1825')
            self.assertIsNone(result['today'])
            self.assertTrue(result['stale'])

    def test_profile_calendar_parses_levels_and_tooltips(self):
        html = """<td id="day1" data-date="2026-01-01" data-level="2"></td>
        <tool-tip for="day1">1,234 contributions on January 1.</tool-tip>
        <td id="day2" data-date="2026-01-02" data-level="0"></td>
        <tool-tip for="day2">No contributions on January 2.</tool-tip>"""
        with patch.object(github, 'download', return_value=html):
            days = github.calendar('SAB1825', datetime(2026, 1, 2).date())
        self.assertEqual(days[0]['count'], 1234)
        self.assertEqual(days[0]['level'], 2)
        self.assertEqual(days[1]['count'], 0)

    def test_calendar_rejects_login_or_changed_markup(self):
        with patch.object(github, 'download', return_value='<html>Sign in</html>'):
            with self.assertRaisesRegex(ValueError, 'could not be read'):
                github.calendar('SAB1825', datetime(2026, 1, 2).date())

    def test_calendar_does_not_invent_unknown_counts(self):
        parser = github.ContributionParser()
        parser.feed('<td data-date="2026-01-02" data-level="3"></td>')
        self.assertIsNone(parser.cells['2026-01-02']['count'])

    def test_calendar_still_loads_when_commit_api_is_unavailable(self):
        days = [{'date': '2026-01-02', 'level': 1, 'count': 2}]
        with patch.object(github, 'search', side_effect=OSError('offline')), patch.object(github, 'calendar', return_value=days):
            result = github.fetch('SAB1825')
        self.assertIsNone(result['today'])
        self.assertEqual(result['days'], days)
        self.assertTrue(result['commitsError'])

    def test_username_cannot_inject_search_qualifiers(self):
        with self.assertRaises(ValueError):
            github.tracker('user repo:another/repo')


if __name__ == '__main__':
    unittest.main()
