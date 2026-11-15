import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch


def load(name, filename):
    path = Path(__file__).resolve().parents[1] / 'scripts' / filename
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


network = load('network', 'network.py')
niri = load('niri_state', 'niri-state.py')


class Adapters(unittest.TestCase):
    def test_nmcli_escaping(self):
        with patch.object(network, 'nm', return_value=r'*:Office\: Wi-Fi:86:WPA2' + '\n'):
            self.assertEqual(network.rows('ignored'), [['*', 'Office: Wi-Fi', '86', 'WPA2']])

    def test_network_matches_saved_ssid_not_connection_name(self):
        def rows(fields, *args):
            return {
                'DEVICE,TYPE,STATE': [['wlan0', 'wifi', 'connected']],
                'NAME,UUID,TYPE,AUTOCONNECT': [['Custom profile', 'abc', '802-11-wireless', 'yes']],
                'IN-USE,SSID,SIGNAL,SECURITY': [['*', 'Office', '90', 'WPA2'], ['', 'Guest', '50', '--']],
            }[fields]
        def nm(*args):
            return 'enabled' if args == ('radio', 'wifi') else 'Office'
        with patch.object(network, 'rows', side_effect=rows), patch.object(network, 'nm', side_effect=nm):
            state = network.snapshot()
        self.assertEqual(state['connectedSsid'], 'Office')
        self.assertEqual(state['networks'][0]['path'], 'saved:abc')
        self.assertTrue(state['networks'][0]['known'])
        self.assertEqual(state['networks'][1]['type'], 'open')

    def test_no_wifi_adapter(self):
        with patch.object(network, 'rows', return_value=[]), patch.object(network, 'nm', return_value='disabled'):
            state = network.snapshot()
        self.assertEqual(state['deviceName'], '')
        self.assertEqual(state['networks'], [])
        self.assertFalse(state['powered'])

    def test_saved_connection_uses_private_password_file(self):
        calls = []
        def nm(*args):
            calls.append(args)
            if 'passwd-file' in args:
                secret = Path(args[-1])
                self.assertEqual(secret.stat().st_mode & 0o777, 0o600)
                self.assertEqual(secret.read_text(), '802-11-wireless-security.psk:sensitive\n')
                self.assertNotIn('sensitive', args)
            return ''
        with patch.object(network, 'nm', side_effect=nm):
            network.action({'op': 'connect', 'path': 'saved:abc', 'password': 'sensitive'})
        self.assertEqual(calls[0][:4], ('connection', 'up', 'uuid', 'abc'))
        self.assertFalse(Path(calls[0][-1]).exists())

    def test_niri_request_envelope(self):
        class Socket:
            def __enter__(self): return self
            def __exit__(self, *args): pass
            def sendall(self, data): self.sent = data
            def makefile(self, mode): return io.StringIO('{"Ok":{"Workspaces":[{"id":7,"idx":1}]}}\n')
        sock = Socket()
        with patch.object(niri, 'connect', return_value=sock):
            result = niri.request('Workspaces')
        self.assertEqual(sock.sent, b'"Workspaces"\n')
        self.assertEqual(result[0]['id'], 7)

    def test_niri_reports_errors(self):
        class Socket:
            def __enter__(self): return self
            def __exit__(self, *args): pass
            def sendall(self, data): pass
            def makefile(self, mode): return io.StringIO('{"Err":"unavailable"}\n')
        with patch.object(niri, 'connect', return_value=Socket()):
            with self.assertRaisesRegex(RuntimeError, 'unavailable'):
                niri.request('Workspaces')


if __name__ == '__main__':
    unittest.main()
