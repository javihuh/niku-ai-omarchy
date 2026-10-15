import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root

  moduleName: "cibo.niku-ai"

  readonly property string barIcon: setting("icon", "\uec81")
  readonly property string shortcut: setting("shortcut", "Super+G")
  readonly property string toggleScript: {
    var url = Qt.resolvedUrl("toggle.sh").toString()
    return url.startsWith("file://") ? url.substring(7) : url
  }
  property bool panelVisible: false
  readonly property bool opened: panelVisible
  readonly property bool popoutSwitchClosing: false

  function run(action) {
    Quickshell.execDetached(["bash", root.toggleScript, action])
    refreshTimer.restart()
  }

  function open() {
    run("open")
  }

  function close() {
    run("close")
  }

  function toggle() {
    run("toggle")
  }

  function closeForPopoutSwitch() {
    close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refreshStatus() {
    if (!statusProcess.running) statusProcess.running = true
  }

  Process {
    id: statusProcess
    command: ["bash", root.toggleScript, "status"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.panelVisible = text.trim() === "visible"
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refreshStatus()
  }

  Timer {
    id: refreshTimer
    interval: 600
    onTriggered: root.refreshStatus()
  }

  IpcHandler {
    target: root.moduleName

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function quit(): void { root.run("quit") }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barIcon
    active: root.panelVisible
    tooltipText: "Niku AI (" + root.shortcut + ") - right-click to quit"
    horizontalMargin: 8.75
    verticalPadding: 8.75

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
      else if (buttonCode === Qt.RightButton) root.run("quit")
    }
  }
}
