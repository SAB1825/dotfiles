#!/usr/bin/env python3
"""NetworkManager adapter; receive action arguments and secrets over stdin."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def nm(*args):
    p = subprocess.run(['nmcli', '--wait', '20', *args], capture_output=True,
                       text=True, env={**os.environ, 'LC_ALL': 'C'})
    if p.returncode:
        raise RuntimeError(p.stderr.strip() or p.stdout.strip())
    return p.stdout.strip()


def rows(fields, *args):
    result = []
    for line in nm('-t', '-e', 'yes', '-f', fields, *args).splitlines():
        values, value, escaped = [], '', False
        for char in line:
            if escaped:
                value += char
                escaped = False
            elif char == '\\':
                escaped = True
            elif char == ':':
                values.append(value)
                value = ''
            else:
                value += char
        result.append(values + [value])
    return result


def snapshot():
    device = next((d for d in rows('DEVICE,TYPE,STATE', 'device', 'status') if d[1] == 'wifi'), None)
    profiles = []
    for name, uuid, kind, auto in rows('NAME,UUID,TYPE,AUTOCONNECT', 'connection', 'show'):
        if kind != '802-11-wireless':
            continue
        ssid = nm('-e', 'no', '-g', '802-11-wireless.ssid', 'connection', 'show', 'uuid', uuid)
        profiles.append(dict(name=ssid, path='saved:' + uuid, type='psk',
                             autoConnect=auto == 'yes', known=True, connected=False))
    networks = []
    if device:
        for used, ssid, strength, security in rows('IN-USE,SSID,SIGNAL,SECURITY', 'device', 'wifi', 'list', 'ifname', device[0], '--rescan', 'no'):
            if not ssid or any(n['name'] == ssid for n in networks):
                continue
            known = next((p for p in profiles if p['name'] == ssid), None)
            kind = '8021x' if '802.1X' in security else ('open' if security in ('', '--') else 'psk')
            networks.append(dict(name=ssid, path=known['path'] if known else 'ssid:' + ssid,
                                 strength=int(strength), type=kind, connected=used == '*',
                                 known=known is not None, autoConnect=known['autoConnect'] if known else False))
    return dict(available=True, powered=nm('radio', 'wifi') == 'enabled',
                deviceName=device[0] if device else '', networks=networks, knownNetworks=profiles,
                connectedSsid=next((n['name'] for n in networks if n['connected']), ''),
                state=device[2] if device else 'No Wi-Fi adapter')


def action(d):
    op = d['op']
    if op == 'radio':
        nm('radio', 'wifi', 'on' if d['on'] else 'off')
    elif op == 'scan':
        nm('device', 'wifi', 'rescan')
    elif op == 'disconnect':
        nm('device', 'disconnect', d['device'])
    elif op in ('forget', 'auto'):
        if not d['path'].startswith('saved:'):
            raise ValueError('Select a saved connection')
        uuid = d['path'][6:]
        if op == 'forget':
            nm('connection', 'delete', 'uuid', uuid)
        else:
            nm('connection', 'modify', 'uuid', uuid, 'connection.autoconnect', 'yes' if d['on'] else 'no')
    elif op == 'connect':
        path, password = d['path'], d.get('password', '')
        if path.startswith('saved:'):
            uuid = path[6:]
        else:
            ssid = path.removeprefix('ssid:')
            # Generate a unique profile name even if an unrelated connection has this SSID as its name.
            import uuid as uuid_module
            uuid = str(uuid_module.uuid4())
            args = ['connection', 'add', 'type', 'wifi', 'ifname', d['device'],
                    'con-name', ssid, 'ssid', ssid, 'connection.uuid', uuid]
            if password:
                args += ['wifi-sec.key-mgmt', 'wpa-psk']
            nm(*args)
        if password:
            if '\n' in password or '\r' in password:
                raise ValueError('Password must be a single line')
            with tempfile.TemporaryDirectory(prefix='phoenix-nm-') as directory:
                secret = Path(directory) / 'password'
                secret.write_text('802-11-wireless-security.psk:' + password + '\n')
                secret.chmod(0o600)
                nm('connection', 'up', 'uuid', uuid, 'passwd-file', str(secret))
        else:
            nm('connection', 'up', 'uuid', uuid)
    else:
        raise ValueError('Unknown network action')


if __name__ == '__main__':
    try:
        if len(sys.argv) > 1 and sys.argv[1] == 'action':
            action(json.loads(sys.stdin.readline()))
            print(json.dumps({'ok': True}))
        else:
            print(json.dumps(snapshot()))
    except (OSError, ValueError, RuntimeError) as error:
        print(json.dumps({'error': str(error)}))
        sys.exit(1)
