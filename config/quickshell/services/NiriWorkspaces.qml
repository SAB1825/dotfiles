pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []

    function handleEvent(event) {
        if (event.WorkspacesChanged) {
            workspaces = event.WorkspacesChanged.workspaces;
        } else if (event.WorkspaceActivated) {
            const active = workspaces.find(workspace => workspace.id === event.WorkspaceActivated.id);
            if (active) {
                workspaces = workspaces.map(workspace => workspace.output === active.output
                    ? Object.assign({}, workspace, { is_active: workspace.id === active.id })
                    : workspace);
            }
        } else if (event.WorkspaceActiveWindowChanged) {
            const change = event.WorkspaceActiveWindowChanged;
            workspaces = workspaces.map(workspace => workspace.id === change.workspace_id
                ? Object.assign({}, workspace, { active_window_id: change.active_window_id })
                : workspace);
        }
    }

    Process {
        command: ["niri", "msg", "--json", "event-stream"]
        running: !!Quickshell.env("NIRI_SOCKET")

        stdout: SplitParser {
            onRead: line => {
                try {
                    root.handleEvent(JSON.parse(line));
                } catch (error) {
                    console.warn("Couldn't read Niri workspace event:", error);
                }
            }
        }
    }
}
