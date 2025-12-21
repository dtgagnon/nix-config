import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Simple Quickshell configuration template
// This creates a basic top panel with a clock
// Customize this file to build your own desktop shell

Scope {
    id: root
    property string currentTime: "Loading..."

    // Create a panel on each connected screen
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: panel
                property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }

                implicitHeight: 32
                color: "#1e1e2e"  // Catppuccin mocha base

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    // Left section - workspace indicator
                    Text {
                        text: "󰣇 Quickshell"
                        color: "#cdd6f4"  // Catppuccin mocha text
                        font.family: "monospace"
                        font.pixelSize: 14
                    }

                    // Center spacer
                    Item {
                        Layout.fillWidth: true
                    }

                    // Right section - clock
                    Text {
                        text: root.currentTime
                        color: "#89b4fa"  // Catppuccin mocha blue
                        font.family: "monospace"
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    // Update the clock every second
    Process {
        id: dateProcess
        command: ["date", "+%Y-%m-%d %H:%M:%S"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.currentTime = this.text.trim()
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateProcess.running = true
    }
}
