import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import "../"

ItemPage {
    headerTitle: qsTr("Effects")

    Effects {
        id: effects
    }

    // Switch for one KWin effect
    component EffectRow: RowLayout {
        id: row
        property string effectId
        property alias title: titleLabel.text
        property string description

        readonly property bool supported: effects.isSupported(effectId)

        Layout.fillWidth: true
        spacing: LingmoUI.Units.largeSpacing * 2

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Label {
                id: titleLabel
            }

            Label {
                text: row.supported ? row.description : qsTr("Requires video acceleration (GPU)")
                visible: text !== ""
                color: LingmoUI.Theme.disabledTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        Switch {
            checked: effects.revision >= 0 && effects.isEnabled(row.effectId)
            enabled: row.supported
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            rightPadding: 0
            onToggled: effects.setEnabled(row.effectId, checked)
        }
    }

    // Choice between two effects that do the same job
    component EffectChoice: RowLayout {
        id: choice
        property alias title: choiceLabel.text
        property string firstId
        property string secondId
        property alias firstText: firstButton.text
        property alias secondText: secondButton.text

        // Only a click changes anything: opening the page must not
        function pick(second) {
            var states = {}
            states[choice.firstId] = !second
            states[choice.secondId] = second
            effects.setEnabledMany(states)
        }

        Layout.fillWidth: true
        spacing: LingmoUI.Units.largeSpacing * 2

        Label {
            id: choiceLabel
        }

        TabBar {
            Layout.fillWidth: true
            currentIndex: effects.revision >= 0 && effects.isEnabled(choice.secondId) ? 1 : 0

            TabButton {
                id: firstButton
                onClicked: choice.pick(false)
            }
            TabButton {
                id: secondButton
                onClicked: choice.pick(true)
            }
        }
    }

    // What a screen corner does when the pointer is pushed into it
    component CornerChoice: ColumnLayout {
        id: cornerChoice
        property string corner
        property alias title: cornerLabel.text

        Layout.fillWidth: true
        spacing: LingmoUI.Units.smallSpacing

        Label {
            id: cornerLabel
        }

        ComboBox {
            Layout.fillWidth: true
            textRole: "text"
            valueRole: "value"
            model: cornerActions
            // indexOfValue() isn't ready while the page loads: look the action up in the model
            currentIndex: {
                var action = effects.revision >= 0 ? effects.cornerAction(cornerChoice.corner) : "none"
                for (var i = 0; i < cornerActions.count; ++i) {
                    if (cornerActions.get(i).value === action)
                        return i
                }
                return 0
            }
            onActivated: effects.setCornerAction(cornerChoice.corner, currentValue)
        }
    }

    ListModel {
        id: cornerActions
        ListElement { value: "none"; text: qsTr("Nothing") }
        ListElement { value: "overview"; text: qsTr("See all windows") }
        ListElement { value: "windowview"; text: qsTr("Current windows") }
        ListElement { value: "showdesktop"; text: qsTr("Show desktop") }
        ListElement { value: "launcher"; text: qsTr("Open the launcher") }
        ListElement { value: "lockscreen"; text: qsTr("Lock screen") }
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing * 2

            RoundedItem {
                Label {
                    text: qsTr("Windows")
                    color: LingmoUI.Theme.disabledTextColor
                }

                EffectRow {
                    effectId: "wobblywindows"
                    title: qsTr("Wobbly windows")
                    description: qsTr("Windows jiggle like jelly while you drag them")
                }

                EffectChoice {
                    title: qsTr("Open and close")
                    firstId: "lingmo_scale"
                    secondId: "glide"
                    firstText: qsTr("Scale")
                    secondText: qsTr("Glide")
                }

                EffectChoice {
                    title: qsTr("Minimize animation")
                    firstId: "lingmo_squash"
                    secondId: "magiclamp"
                    firstText: qsTr("Default")
                    secondText: qsTr("Magic Lamp")
                }

                EffectRow {
                    effectId: "fallapart"
                    title: qsTr("Fall apart")
                    description: qsTr("Closed windows break into pieces")
                }

                EffectRow {
                    effectId: "maximize"
                    title: qsTr("Animated maximize")
                    description: qsTr("Windows grow smoothly when maximized or restored")
                }

                EffectRow {
                    effectId: "translucency"
                    title: qsTr("Translucent while moving")
                    description: qsTr("See what is behind a window while you drag it")
                }

                EffectRow {
                    effectId: "diminactive"
                    title: qsTr("Dim inactive windows")
                    description: qsTr("The window you are using stands out")
                }

                EffectRow {
                    effectId: "frozenapp"
                    title: qsTr("Grey out frozen apps")
                    description: qsTr("Apps that stop responding turn grey")
                }
            }

            RoundedItem {
                Label {
                    text: qsTr("Desktop and menus")
                    color: LingmoUI.Theme.disabledTextColor
                }

                EffectChoice {
                    title: qsTr("Switching desktops")
                    firstId: "slide"
                    secondId: "fadedesktop"
                    firstText: qsTr("Slide")
                    secondText: qsTr("Fade")
                }

                EffectRow {
                    effectId: "windowaperture"
                    title: qsTr("Show desktop")
                    description: qsTr("Windows move out to the corners to show the desktop")
                }

                EffectRow {
                    effectId: "lingmo_popups"
                    title: qsTr("Animated menus")
                    description: qsTr("Menus and tooltips fade and grow in")
                }
            }

            RoundedItem {
                Label {
                    text: qsTr("Hot corners")
                    color: LingmoUI.Theme.disabledTextColor
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Push the pointer into a corner of the screen to run an action.")
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: LingmoUI.Units.largeSpacing * 2
                    rowSpacing: LingmoUI.Units.largeSpacing

                    CornerChoice {
                        corner: "TopLeft"
                        title: qsTr("Top left")
                    }
                    CornerChoice {
                        corner: "TopRight"
                        title: qsTr("Top right")
                    }
                    CornerChoice {
                        corner: "BottomLeft"
                        title: qsTr("Bottom left")
                    }
                    CornerChoice {
                        corner: "BottomRight"
                        title: qsTr("Bottom right")
                    }
                }
            }

            RoundedItem {
                Label {
                    text: qsTr("Window switcher (Alt+Tab)")
                    color: LingmoUI.Theme.disabledTextColor
                }

                TabBar {
                    Layout.fillWidth: true
                    currentIndex: effects.switcherLayout === "ling_flip" ? 1 : 0

                    TabButton {
                        text: qsTr("Strip")
                        onClicked: effects.switcherLayout = "ling_thumbnail"
                    }
                    TabButton {
                        text: qsTr("Flip")
                        onClicked: effects.switcherLayout = "ling_flip"
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: LingmoUI.Theme.disabledTextColor
                    text: effects.switcherLayout === "ling_flip"
                          ? qsTr("Windows stacked like the pages of a book; each Tab turns a page.")
                          : qsTr("Window previews side by side.")
                }
            }

            RoundedItem {
                Label {
                    text: qsTr("Mouse")
                    color: LingmoUI.Theme.disabledTextColor
                }

                EffectRow {
                    effectId: "mouseclick"
                    title: qsTr("Show mouse clicks")
                    description: qsTr("A ring appears where you click, handy for recordings")
                }
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }
        }
    }
}
