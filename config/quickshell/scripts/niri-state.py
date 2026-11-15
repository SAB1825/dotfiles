#!/usr/bin/env python3
"""Publish niri snapshots after IPC events; reconnect if niri restarts."""
import json
import os
import select
import socket
import sys
import time


def connect():
    sock = socket.socket(socket.AF_UNIX)
    sock.settimeout(3)
    sock.connect(os.environ["NIRI_SOCKET"])
    return sock


def request(name):
    with connect() as sock:
        sock.sendall((json.dumps(name) + "\n").encode())
        with sock.makefile("r") as stream:
            reply = json.loads(stream.readline())
        if "Err" in reply:
            raise RuntimeError(reply["Err"])
        return reply["Ok"][name]


def snapshot():
    return {"connected": True, "workspaces": request("Workspaces"),
            "windows": request("Windows"), "outputs": request("Outputs"),
            "focusedOutput": request("FocusedOutput")}


def publish(state):
    print(json.dumps(state, separators=(",", ":")), flush=True)


def run():
    while True:
        try:
            with connect() as events:
                events.sendall(b'"EventStream"\n')
                # Subscribe before querying so that no changes are lost.
                publish(snapshot())
                events.settimeout(None)
                pending = b""
                dirty = False
                deadline = 0
                while True:
                    ready, _, _ = select.select([events], [], [],
                                                max(0, deadline - time.monotonic()) if dirty else None)
                    if ready:
                        chunk = events.recv(65536)
                        if not chunk:
                            raise ConnectionError("niri event stream closed")
                        pending += chunk
                        while b"\n" in pending:
                            line, pending = pending.split(b"\n", 1)
                            event = json.loads(line)
                            # Ignore pointer movement and animation-only events.
                            if any(key.startswith(("Window", "Workspace", "Output"))
                                   and key not in ("WindowLayoutsChanged", "WorkspaceActiveWindowChanged")
                                   for key in event):
                                if not dirty:
                                    deadline = time.monotonic() + 0.06
                                dirty = True
                    if dirty and time.monotonic() >= deadline:
                        publish(snapshot())
                        dirty = False
        except (OSError, ValueError, KeyError, RuntimeError) as error:
            publish({"connected": False, "workspaces": [], "windows": [],
                     "outputs": {}, "focusedOutput": None})
            print(f"niri-state: {error}", file=sys.stderr, flush=True)
            time.sleep(2)


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--focus-workspace":
        with connect() as sock:
            action = {"Action": {"FocusWorkspace": {"reference": {"Id": int(sys.argv[2])}}}}
            sock.sendall((json.dumps(action) + "\n").encode())
            reply = json.loads(sock.makefile("r").readline())
            if "Err" in reply:
                sys.exit(str(reply["Err"]))
    else:
        run()
