#!/usr/bin/env python3
"""Public GitHub contribution calendar and today's indexed commits; read-only."""
import argparse
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import time
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

SCHEMA = 2


def download(url, accept):
    request = Request(url, headers={'Accept': accept, 'User-Agent': 'Phoenix-Commit-Tracker',
                                   'X-GitHub-Api-Version': '2022-11-28'})
    with urlopen(request, timeout=15) as response:
        return response.read().decode('utf-8')


def search(username, date_range):
    query = urlencode({'q': f'author:{username} author-date:{date_range} is:public',
                       'sort': 'author-date', 'order': 'desc', 'per_page': 30})
    result = json.loads(download('https://api.github.com/search/commits?' + query,
                                 'application/vnd.github+json'))
    if result.get('incomplete_results'):
        raise ValueError('GitHub returned incomplete commit results. Try again later.')
    return result


class ContributionParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.cells = {}
        self.ids = {}
        self.tooltip = None
        self.tooltip_text = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        date = attrs.get('data-date', '')
        if re.fullmatch(r'\d{4}-\d{2}-\d{2}', date) and 'data-level' in attrs:
            level = int(attrs['data-level'])
            count = attrs.get('data-count')
            self.cells[date] = {'date': date, 'level': max(0, min(4, level)),
                                'count': int(count) if count is not None else (0 if level == 0 else None)}
            if attrs.get('id'):
                self.ids[attrs['id']] = date
        if tag == 'tool-tip':
            self.tooltip = attrs.get('for')
            self.tooltip_text = []

    def handle_data(self, data):
        if self.tooltip is not None:
            self.tooltip_text.append(data)

    def handle_endtag(self, tag):
        if tag == 'tool-tip':
            date = self.ids.get(self.tooltip)
            text = ''.join(self.tooltip_text).strip()
            if date:
                match = re.search(r'([\d,]+) contributions?\b', text, re.I)
                if match:
                    self.cells[date]['count'] = int(match.group(1).replace(',', ''))
                elif re.search(r'No contributions?\b', text, re.I):
                    self.cells[date]['count'] = 0
            self.tooltip = None
            self.tooltip_text = []


def calendar(username, today):
    start = today - timedelta(days=364)
    query = urlencode({'from': start.isoformat(), 'to': today.isoformat()})
    html = download(f'https://github.com/users/{username}/contributions?{query}', 'text/html')
    parser = ContributionParser()
    parser.feed(html)
    cells = [cell for date, cell in sorted(parser.cells.items()) if start.isoformat() <= date <= today.isoformat()]
    if not cells:
        raise ValueError('GitHub contribution calendar could not be read. Its page format may have changed.')
    return cells


def error_message(error):
    if isinstance(error, HTTPError):
        code = error.code
        error.close()
        return 'GitHub rate limit or access restriction. Try again later.' if code in (403, 429) else f'GitHub returned HTTP {code}.'
    if isinstance(error, ValueError):
        return str(error)
    return 'Unable to reach GitHub. Check your connection.'


def fetch(username, now=None):
    now = now or datetime.now(timezone.utc)
    today = now.date()
    result = {'schema': SCHEMA, 'username': username, 'date': today.isoformat(),
              'today': None, 'recent': [], 'days': [], 'calendarError': '', 'commitsError': '',
              'updated': now.isoformat(), 'error': '', 'stale': False}
    try:
        daily = search(username, today.isoformat())
        result['today'] = daily['total_count']
        for item in daily['items']:
            url = item.get('html_url', '')
            if url.startswith('https://github.com/'):
                message = item['commit']['message'].splitlines()
                result['recent'].append({'title': message[0] if message else '(no message)',
                                         'repo': item['repository']['full_name'], 'url': url,
                                         'sha': item['sha'][:7]})
    except (OSError, ValueError, KeyError, TypeError, IndexError) as error:
        result['commitsError'] = error_message(error)
    try:
        result['days'] = calendar(username, today)
    except (OSError, ValueError, KeyError, TypeError) as error:
        result['calendarError'] = error_message(error)
    if result['today'] is None and not result['days']:
        raise ValueError(result['commitsError'] or result['calendarError'])
    return result


def read_cache(path):
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def tracker(username, force=False):
    if not re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?', username):
        raise ValueError('Invalid GitHub username')
    directory = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'phoenix'
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f'github-{username}.json'
    cached = read_cache(path)
    if cached.get('schema') != SCHEMA:
        cached = {}
    stamp = time.time()
    date = datetime.now(timezone.utc).date().isoformat()
    if cached.get('date') == date and stamp - cached.get('attempted', 0) < (30 if force else 300):
        return cached
    try:
        result = fetch(username)
    except (OSError, ValueError, KeyError, TypeError, IndexError) as error:
        result = cached if cached.get('date') == date else {'schema': SCHEMA, 'username': username,
                  'date': date, 'today': None, 'recent': [], 'days': [], 'updated': ''}
        result = {**result, 'error': error_message(error), 'stale': True}
    result['attempted'] = stamp
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(result))
    temporary.replace(path)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--username', default='SAB1825')
    parser.add_argument('--force', action='store_true')
    args = parser.parse_args()
    try:
        print(json.dumps(tracker(args.username, args.force)))
    except (OSError, ValueError) as error:
        print(json.dumps({'error': str(error), 'stale': True}))
