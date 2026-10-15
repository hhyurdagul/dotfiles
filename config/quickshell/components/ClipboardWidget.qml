import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: clipboardWidget
    popupWidth: 460
    popupHeight: 510

    property var entries: []
    property string query: ""
    property bool busy: false
    property bool refreshPending: false
    property int openGeneration: 0
    property int requestGeneration: 0
    property bool confirmingClear: false
    property string operation: ""
    property string responseLine: ""
    property string statusMessage: ""
    property bool actionFailed: false
    readonly property var visibleEntries: {
        var needle = query.toLocaleLowerCase().trim()
        return entries.filter(entry => !needle || entry.preview.toLocaleLowerCase().includes(needle))
    }

    function refresh() {
        if (busy) {
            refreshPending = true
            return
        }
        runAction("list")
    }

    function runAction(action, identifier) {
        if (busy || helper.running) return
        var argv = ["clipboard-history", action]
        if (action === "clear") {
            if (!confirmingClear) return
            argv.push("--confirm")
        } else if (action === "copy" || action === "delete") {
            if (!/^[0-9]{1,20}$/.test(String(identifier))) return
            argv.push(String(identifier))
        }
        operation = action
        requestGeneration = openGeneration
        responseLine = ""
        statusMessage = ""
        actionFailed = false
        busy = true
        helper.command = argv
        helper.running = true
        requestTimeout.restart()
    }

    function finishRequest(exitCode) {
        requestTimeout.stop()
        if (!busy) return
        var result = null
        try {
            result = JSON.parse(responseLine)
        } catch (error) {
            // Never log subprocess output: list replies contain clipboard previews.
        }
        var success = exitCode === 0 && result && result.ok === true
        if (success && result.entries !== undefined) {
            if (!Array.isArray(result.entries) || result.entries.some(entry =>
                typeof entry.id !== "string" || !/^[0-9]{1,20}$/.test(entry.id)
                || typeof entry.preview !== "string")) {
                success = false
            } else {
                entries = result.entries
            }
        }
        actionFailed = !success
        // Error text is local and static, never supplied by clipboard tools.
        statusMessage = success ? (operation === "delete" ? "Entry deleted."
            : operation === "clear" ? "History cleared." : "")
            : "Clipboard request failed. Refresh to try again."
        if (success && operation === "clear") confirmingClear = false
        if (success && operation === "copy" && requestGeneration === openGeneration)
            dropdownOpen = false
        busy = false
        if (refreshPending) {
            refreshPending = false
            Qt.callLater(refresh)
        }
    }

    onOpened: {
        openGeneration += 1
        query = ""
        confirmingClear = false
        refresh()
    }
    onDropdownOpenChanged: {
        if (!dropdownOpen) confirmingClear = false
    }

    Process {
        id: helper
        stdout: SplitParser {
            onRead: data => clipboardWidget.responseLine = data
        }
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => clipboardWidget.finishRequest(exitCode)
    }

    Timer {
        id: requestTimeout
        interval: 30000
        onTriggered: {
            clipboardWidget.busy = false
            clipboardWidget.refreshPending = false
            clipboardWidget.actionFailed = true
            clipboardWidget.statusMessage = "Clipboard request timed out. Refresh to try again."
            helper.running = false
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰅌"
        color: clipboardWidget.dropdownOpen ? Theme.colBlue : Theme.colFgDim
        font.pixelSize: Theme.fontSize + 4
        font.family: Theme.fontFamily
        Accessible.name: "Clipboard history"
    }

    component ActionButton: Button {
        id: control
        property bool danger: false
        implicitHeight: Theme.fontSize + Theme.itemPadding * 2
        horizontalPadding: Theme.itemPadding
        contentItem: Text {
            text: control.text
            textFormat: Text.PlainText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: !control.enabled ? Theme.colMuted : control.danger ? Theme.colRed : Theme.colFg
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: Theme.itemRadius
            color: control.down || control.hovered ? Theme.colHoverStrong
                : control.danger ? Theme.colDangerSurface : Theme.colSurface
            border.width: control.activeFocus ? Theme.cardBorderWidth : 0
            border.color: Theme.colBlue
        }
    }

    popupContent: Component {
        FocusScope {
            id: popupScope
            focus: true

            function focusSearch() {
                if (clipboardWidget.dropdownOpen) searchInput.forceActiveFocus()
            }

            Component.onCompleted: Qt.callLater(focusSearch)
            Connections {
                target: clipboardWidget
                function onDropdownOpenChanged() {
                    if (clipboardWidget.dropdownOpen) Qt.callLater(popupScope.focusSearch)
                }
            }
            Keys.onEscapePressed: event => {
                if (clipboardWidget.confirmingClear) {
                    clipboardWidget.confirmingClear = false
                    searchInput.forceActiveFocus()
                } else {
                    clipboardWidget.dropdownOpen = false
                }
                event.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.densePadding

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.densePadding
                    Text {
                        Layout.fillWidth: true
                        text: "Clipboard history"
                        color: Theme.colFg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                    }
                    ActionButton {
                        text: "Refresh"
                        enabled: !clipboardWidget.busy && !clipboardWidget.confirmingClear
                        onClicked: clipboardWidget.refresh()
                    }
                    ActionButton {
                        text: "Clear all"
                        danger: true
                        enabled: !clipboardWidget.busy && clipboardWidget.entries.length > 0
                            && !clipboardWidget.confirmingClear
                        onClicked: {
                            clipboardWidget.confirmingClear = true
                            Qt.callLater(() => cancelClear.forceActiveFocus())
                        }
                    }
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    enabled: !clipboardWidget.confirmingClear
                    text: clipboardWidget.query
                    onTextEdited: clipboardWidget.query = text
                    placeholderText: "Search history previews…"
                    placeholderTextColor: Theme.colMuted
                    color: Theme.colFg
                    selectionColor: Theme.colBlue
                    selectedTextColor: Theme.colBg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    padding: Theme.itemPadding
                    background: Rectangle {
                        color: Theme.colSurface
                        radius: Theme.itemRadius
                        border.width: Theme.cardBorderWidth
                        border.color: searchInput.activeFocus ? Theme.colBlue : Theme.cardBorderColor
                    }
                    Keys.onDownPressed: {
                        if (historyList.count > 0) {
                            historyList.currentIndex = Math.max(0, historyList.currentIndex)
                            historyList.forceActiveFocus()
                        }
                    }
                    onAccepted: {
                        if (clipboardWidget.visibleEntries.length > 0 && !clipboardWidget.busy)
                            clipboardWidget.runAction("copy", clipboardWidget.visibleEntries[0].id)
                    }
                    Accessible.name: "Search clipboard history previews"
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: confirmationContent.implicitHeight + Theme.itemPadding * 2
                    visible: clipboardWidget.confirmingClear
                    color: Theme.colDangerSurface
                    radius: Theme.itemRadius
                    border.color: Theme.colRed
                    border.width: Theme.cardBorderWidth
                    ColumnLayout {
                        id: confirmationContent
                        anchors.fill: parent
                        anchors.margins: Theme.itemPadding
                        spacing: Theme.densePadding
                        Text {
                            Layout.fillWidth: true
                            text: "Delete all stored history? This cannot be undone. The current clipboard is not cleared."
                            wrapMode: Text.WordWrap
                            color: Theme.colFg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: Theme.densePadding
                            ActionButton {
                                id: cancelClear
                                text: "Cancel"
                                enabled: !clipboardWidget.busy
                                onClicked: {
                                    clipboardWidget.confirmingClear = false
                                    searchInput.forceActiveFocus()
                                }
                            }
                            ActionButton {
                                text: "Delete all history"
                                danger: true
                                enabled: !clipboardWidget.busy
                                onClicked: clipboardWidget.runAction("clear")
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: clipboardWidget.busy || clipboardWidget.statusMessage.length > 0
                    text: clipboardWidget.busy ? (clipboardWidget.operation === "list" ? "Loading history…"
                        : clipboardWidget.operation === "copy" ? "Copying entry…" : "Updating history…")
                        : clipboardWidget.statusMessage
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    color: clipboardWidget.actionFailed ? Theme.colRed : Theme.colFgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        visible: !clipboardWidget.busy && !clipboardWidget.actionFailed
                            && clipboardWidget.visibleEntries.length === 0
                        text: clipboardWidget.entries.length === 0
                            ? "No clipboard history yet.\nCopy some text or an image to get started."
                            : "No entries match your search."
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: Theme.colMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    ListView {
                        id: historyList
                        anchors.fill: parent
                        clip: true
                        spacing: Theme.densePadding
                        model: clipboardWidget.visibleEntries
                        enabled: !clipboardWidget.busy && !clipboardWidget.confirmingClear
                        keyNavigationEnabled: true
                        activeFocusOnTab: true
                        onModelChanged: currentIndex = count > 0 ? 0 : -1
                        Keys.onReturnPressed: {
                            if (currentIndex >= 0 && currentIndex < count)
                                clipboardWidget.runAction("copy", clipboardWidget.visibleEntries[currentIndex].id)
                        }
                        Keys.onEnterPressed: {
                            if (currentIndex >= 0 && currentIndex < count)
                                clipboardWidget.runAction("copy", clipboardWidget.visibleEntries[currentIndex].id)
                        }
                        Keys.onDeletePressed: {
                            if (currentIndex >= 0 && currentIndex < count)
                                clipboardWidget.runAction("delete", clipboardWidget.visibleEntries[currentIndex].id)
                        }
                        Keys.onUpPressed: event => {
                            if (currentIndex <= 0) searchInput.forceActiveFocus()
                            else decrementCurrentIndex()
                            event.accepted = true
                        }
                        ScrollBar.vertical: ScrollBar {}
                        delegate: RowLayout {
                            id: entryRow
                            required property var modelData
                            required property int index
                            width: historyList.width
                            height: Theme.fontSize * 3 + Theme.itemPadding * 2
                            spacing: Theme.densePadding

                            Button {
                                id: copyButton
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                padding: Theme.itemPadding
                                Accessible.name: "Copy clipboard entry " + entryRow.modelData.preview
                                onClicked: {
                                    historyList.currentIndex = entryRow.index
                                    clipboardWidget.runAction("copy", entryRow.modelData.id)
                                }
                                background: Rectangle {
                                    radius: Theme.itemRadius
                                    color: copyButton.hovered || copyButton.down ? Theme.colHoverStrong
                                        : historyList.currentIndex === entryRow.index ? Theme.colSelected : Theme.colSurface
                                    border.width: copyButton.activeFocus ? Theme.cardBorderWidth : 0
                                    border.color: Theme.colBlue
                                }
                                contentItem: ColumnLayout {
                                    spacing: 0
                                    Text {
                                        Layout.fillWidth: true
                                        text: entryRow.modelData.preview
                                        textFormat: Text.PlainText
                                        wrapMode: Text.WrapAnywhere
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        color: Theme.colFg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: entryRow.modelData.kind === "binary" ? "Image / binary · click to copy" : "Text · click to copy"
                                        color: Theme.colMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }
                            }
                            ActionButton {
                                text: "Delete"
                                danger: true
                                Accessible.name: "Delete clipboard entry " + entryRow.modelData.id
                                onClicked: clipboardWidget.runAction("delete", entryRow.modelData.id)
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Enter: copy · ↓/↑: select · Delete: remove · Esc: close\nImages use metadata previews; text previews are limited to 2,000 characters."
                    wrapMode: Text.WordWrap
                    color: Theme.colMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }
    }
}
