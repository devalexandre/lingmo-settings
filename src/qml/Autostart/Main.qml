import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import "../"

ItemPage {
    headerTitle: qsTr("Startup")

    Autostart {
        id: autostart
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing * 2

            RoundedItem {
                RowLayout {
                    Label {
                        text: qsTr("Apps opened at login")
                        color: LingmoUI.Theme.disabledTextColor
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Add command")
                        icon.name: "utilities-terminal"
                        onClicked: commandDialog.edit()
                    }

                    Button {
                        text: qsTr("Add app")
                        icon.name: "list-add"
                        flat: true
                        onClicked: appPicker.pick()
                    }
                }

                Label {
                    visible: entries.count === 0
                    text: qsTr("No apps open at login")
                    color: LingmoUI.Theme.disabledTextColor
                }

                Repeater {
                    id: entries
                    model: autostart

                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: row.implicitHeight + LingmoUI.Units.smallSpacing * 2

                        RowLayout {
                            id: row
                            anchors.fill: parent
                            spacing: LingmoUI.Units.largeSpacing

                            LingmoUI.IconItem {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                source: model.iconName || "application-x-executable"
                                opacity: model.enabled ? 1 : 0.5
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Label {
                                    text: model.name
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    opacity: model.enabled ? 1 : 0.6
                                }

                                Label {
                                    text: model.comment || model.command
                                    visible: text !== ""
                                    color: LingmoUI.Theme.disabledTextColor
                                    font.pointSize: Qt.application.font.pointSize * 0.9
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            ToolButton {
                                icon.name: "edit-delete"
                                visible: model.removable
                                ToolTip.text: qsTr("Remove")
                                ToolTip.visible: hovered
                                onClicked: autostart.remove(model.fileName)
                            }

                            Switch {
                                checked: model.enabled
                                onToggled: autostart.setEnabled(model.fileName, checked)
                            }
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: LingmoUI.Units.largeSpacing
                wrapMode: Text.WordWrap
                color: LingmoUI.Theme.disabledTextColor
                text: qsTr("Changes apply at the next login.")
            }
        }
    }

    // Pick an installed app
    Popup {
        id: appPicker
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 440
        height: Math.min(520, parent ? parent.height - 80 : 520)
        modal: true
        focus: true
        padding: LingmoUI.Units.largeSpacing * 1.5

        property var apps: []

        function pick() {
            if (apps.length === 0)
                apps = autostart.applications
            search.text = ""
            open()
            search.forceActiveFocus()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing

            Label {
                text: qsTr("Add app")
                font.weight: Font.DemiBold
                font.pointSize: Qt.application.font.pointSize * 1.15
            }

            TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: qsTr("Search")
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: appPicker.apps.filter(a => search.text === ""
                                             || a.name.toLowerCase().indexOf(search.text.toLowerCase()) !== -1)
                ScrollBar.vertical: ScrollBar {}

                delegate: ItemDelegate {
                    width: ListView.view.width
                    onClicked: {
                        autostart.addApplication(modelData.path)
                        appPicker.close()
                    }

                    contentItem: RowLayout {
                        spacing: LingmoUI.Units.largeSpacing

                        LingmoUI.IconItem {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            source: modelData.icon || "application-x-executable"
                        }

                        Label {
                            text: modelData.name
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            RowLayout {
                Item { Layout.fillWidth: true }
                Button {
                    text: qsTr("Cancel")
                    onClicked: appPicker.close()
                }
            }
        }
    }

    // A command or script of the user's own
    Popup {
        id: commandDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 420
        modal: true
        focus: true
        padding: LingmoUI.Units.largeSpacing * 1.5

        function edit() {
            nameField.text = ""
            commandField.text = ""
            errorLabel.text = ""
            open()
            nameField.forceActiveFocus()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing

            Label {
                text: qsTr("Add command")
                font.weight: Font.DemiBold
                font.pointSize: Qt.application.font.pointSize * 1.15
            }

            TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: qsTr("Name (e.g. Sync notes)")
            }

            TextField {
                id: commandField
                Layout.fillWidth: true
                placeholderText: qsTr("Command (e.g. ~/bin/sync.sh)")
                onAccepted: addButton.clicked()
            }

            Label {
                id: errorLabel
                visible: text !== ""
                color: "#FF453A"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: LingmoUI.Units.largeSpacing
                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    onClicked: commandDialog.close()
                }

                Button {
                    id: addButton
                    text: qsTr("Add")
                    flat: true
                    onClicked: {
                        const error = autostart.addCommand(nameField.text, commandField.text)
                        if (error === "")
                            commandDialog.close()
                        else
                            errorLabel.text = error
                    }
                }
            }
        }
    }
}
