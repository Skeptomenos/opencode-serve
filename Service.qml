import QtQuick
import Quickshell
import Quickshell.Io

// Headless status service for the local OpenCode v2 server.
// Polls the health endpoint without credentials: any HTTP answer
// (200 with auth, 401 without) means the server is up.
// Connection refused means it is down. No password needed.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string serverUrl: "http://127.0.0.1:4096"
  property bool online: false
  property string lastCode: ""
  property string lastCheck: ""

  function check() {
    if (!healthProcess.running) healthProcess.running = true
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.check()
  }

  Process {
    id: healthProcess
    command: ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "5", root.serverUrl + "/api/health"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.lastCode = text.trim()
        root.online = root.lastCode === "200" || root.lastCode === "401"
        root.lastCheck = new Date().toISOString()
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text.trim() !== "") {
          root.online = false
          root.lastCheck = new Date().toISOString()
        }
      }
    }
  }
}
