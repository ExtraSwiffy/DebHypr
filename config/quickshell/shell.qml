import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property color bg: "#1f2937"
    readonly property color bgDark: "#374151"
    readonly property color bgLight: "#4b5563"
    readonly property color text: "#e5e7eb"
    readonly property color muted: "#9ca3af"
    readonly property color blue: "#3b82f6"
    readonly property color updateRed: "#ef4444"

    property string weatherTemp: "--°F"
    property string weatherIcon: "󰖐"
    property bool updatesAvailable: false

    property string wallpaperDir: "/home/extraswiffy/Pictures/Wallpapers"
    property var wallpapers: []
    property int wallpaperIndex: 0
    property bool wallpaperPickerOpen: false
    property bool wallpaperChanging: false
    property string wallpaperCurrent: ""
    property string wallpaperPrevious: ""

    property bool menuOpen: false
    property bool confOpen: false

    function toggleWallpaperPicker() {
    wallpaperPickerOpen = !wallpaperPickerOpen
}

IpcHandler {
    target: "wallpaper"

    function toggle() {
        root.toggleWallpaperPicker()
    }

    function close() {
        root.closeWallpaperPicker()
    }
}

IpcHandler {
    target: "quickshell"

    function reload() {
        Quickshell.reload(false)
    }
}

function closeWallpaperPicker() {
    wallpaperPickerOpen = false
}

function loadWallpapers() {
    wallpaperListProcess.running = true
}

function applyWallpaper(path) {
    if (path === "")
        return

    wallpaperPrevious = wallpaperCurrent
    wallpaperCurrent = path
    wallpaperChanging = true

    wallpaperApplyProcess.command = [
        "hyprctl",
        "hyprpaper",
        "wallpaper",
        "HDMI-A-1," + path
    ]

    wallpaperApplyProcess.running = true
}

    











    property real menuX: 0
    property real menuY: 0

    function closeMenus() {
        menuOpen = false
        confOpen = false
    }

    function openConfig(key) {
        let path = ""

        switch (key) {
        case "quickshell":
            path = "~/.config/quickshell/shell.qml"
            break

        case "hyprland":
            path = "~/.config/hypr/hyprland.conf"
            break

        case "hyprpaper":
            path = "~/.config/hypr/hyprpaper.conf"
            break

        case "ghostty":
            path = "~/.config/ghostty/config.ghostty"
            break

        case "starship":
            path = "~/.config/starship.toml"
            break

        case "fastfetch":
            path = "~/.config/fastfetch/config.jsonc"
            break
        }

        if (path === "")
            return

        configProcess.command = [
    "ghostty",
    "-e",
    "bash",
    "-lc",
    "nano " + path
]

        configProcess.running = true
        closeMenus()
    }

    function runMenuAction(action) {
        switch (action) {
        case "terminal":
            terminalProcess.command = ["ghostty"]
            terminalProcess.running = true
            break

        case "files":
            fileManagerProcess.command = ["dolphin"]
            fileManagerProcess.running = true
            break

        case "quickshell":
    quickshellReloadProcess.command = [
        "quickshell",
        "ipc",
        "call",
        "quickshell",
        "reload"
    ]
    quickshellReloadProcess.running = true
    break

        case "hyprland":
            hyprlandReloadProcess.command = [
                "hyprctl",
                "reload"
            ]
            hyprlandReloadProcess.running = true
            break

        case "windows":
            windowsProcess.command = [
                "bash",
                "-lc",
                "systemctl reboot --boot-loader-entry=auto-windows"
            ]
            windowsProcess.running = true
            break

        case "logout":
            logoutProcess.command = [
                "hyprctl",
                "dispatch",
                "exit"
            ]
            logoutProcess.running = true
            break
        }

        closeMenus()
    }

    function activeSpotifyPlayer() {
        for (let i = 0; i < Mpris.players.values.length; i++) {
            const player = Mpris.players.values[i]

            if (player.identity &&
                player.identity.toLowerCase().includes("spotify") &&
                player.isPlaying) {
                return player
            }
        }

        return null
    }

    function activeFirefoxPlayer() {
        for (let i = 0; i < Mpris.players.values.length; i++) {
            const player = Mpris.players.values[i]

            if (player.identity &&
                player.identity.toLowerCase().includes("firefox") &&
                player.isPlaying) {
                return player
            }
        }

        return null
    }

    function currentWorkspaceTitle() {
        const workspace = Hyprland.focusedWorkspace
        const active = Hyprland.activeToplevel

        if (!workspace || !active)
            return "Desktop"

        if (!active.workspace)
            return "Desktop"

        if (active.workspace.id !== workspace.id)
            return "Desktop"

        if (!active.title || active.title.length === 0)
            return "Desktop"

        return active.title
    }

    function weatherSymbol(code) {
        if (code === 0)
            return "󰖙"

        if (code <= 3)
            return "󰖕"

        if (code <= 48)
            return "󰖑"

        if (code <= 67)
            return "󰖗"

        if (code <= 77)
            return "󰖘"

        if (code <= 82)
            return "󰖖"

        if (code <= 99)
            return "󰼰"

        return "󰖐"
    }

    Process {
        id: weatherProcess

        command: [
            "curl",
            "-s",
            "https://api.open-meteo.com/v1/forecast?latitude=34.9154&longitude=-85.1091&current=temperature_2m,weather_code&temperature_unit=fahrenheit"
        ]

        stdout: StdioCollector {
            id: weatherOutput

            onStreamFinished: {
                try {
                    const data = JSON.parse(text)

                    root.weatherTemp =
                        Math.round(data.current.temperature_2m) + "°F"

                    root.weatherIcon =
                        root.weatherSymbol(data.current.weather_code)
                } catch (error) {
                    console.log("Weather parse error:", error)
                }
            }
        }
    }

    Process {
        id: updateProcess

        command: [
            "bash",
            "-c",
            "apt list --upgradable 2>/dev/null | tail -n +2"
        ]

        stdout: StdioCollector {
            id: updateOutput

            onStreamFinished: {
                root.updatesAvailable =
                    text.trim().length > 0
            }
        }
    }

    Process {
        id: upgradeProcess

        command: [
            "ghostty",
            "-e",
            "bash",
            "-c",
            "sudo apt update && sudo apt upgrade; echo; echo 'Press Enter to close...'; read"
        ]

        onRunningChanged: {
            if (!upgradeProcess.running) {
                updateProcess.running = true
            }
        }
    }

        Process { id: terminalProcess }

    Process { id: fileManagerProcess }

    Process { id: configProcess }

    Process { id: quickshellReloadProcess }

    Process { id: hyprlandReloadProcess }

    Process { id: windowsProcess }

    Process { id: logoutProcess }

    Process {
    id: wallpaperListProcess

    command: [
        "bash",
        "-lc",
        "find \"" + root.wallpaperDir + "\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%f\\n' | sort"
    ]

    stdout: StdioCollector {
        id: wallpaperListOutput

        onStreamFinished: {
            const lines = text
                .trim()
                .split("\n")
                .filter(line => line.length > 0)

            const result = []

            for (let i = 0; i < lines.length; i++) {
                result.push(
                    root.wallpaperDir + "/" + lines[i]
                )
            }

            root.wallpapers = result

            if (root.wallpaperIndex >= result.length)
                root.wallpaperIndex = Math.max(0, result.length - 1)
        }
    }
}

Process {
    id: wallpaperApplyProcess

    onRunningChanged: {
        if (!running)
            root.wallpaperChanging = false
    }
}

    
    Variants {
    model: Quickshell.screens

    PanelWindow {
        id: desktopLayer

        required property var modelData

        screen: modelData

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1

        MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
            root.menuX = mouse.x
            root.menuY = mouse.y
            root.menuOpen = true
            root.confOpen = false
        } else if (mouse.button === Qt.LeftButton) {
            root.closeMenus()
        }
    }
}

        Rectangle {
            id: contextMenu

            visible: root.menuOpen

            z: 100

            x: Math.min(
                root.menuX,
                parent.width - width - 10
            )

            y: Math.min(
                root.menuY,
                parent.height - height - 10
            )

            width: 220
            height: root.confOpen ? 292 : 258

            radius: 12

            color: root.bg

            border.color: root.bgLight
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 6

                spacing: 2

                Repeater {
                    model: [
                        {
                            label: "Open Terminal",
                            action: "terminal"
                        },
                        {
                            label: "Open File Manager",
                            action: "files"
                        },
                        {
                            label: "Reload Quickshell",
                            action: "quickshell"
                        },
                        {
                            label: "Reload Hyprland",
                            action: "hyprland"
                        },
                        {
                            label: "DebHypr Conf",
                            action: "conf"
                        },
                        {
                            label: "Reboot to Windows",
                            action: "windows"
                        },
                        {
                            label: "Log Out",
                            action: "logout"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: parent.width
                        height: 34

                        radius: 7

                        color:
                            menuMouse.containsMouse
                            ? root.bgDark
                            : "transparent"

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            text: modelData.label

                            color: root.text

                            font.pixelSize: 13
                        }

                        Text {
                            visible:
                                modelData.action === "conf"

                            anchors {
                                right: parent.right
                                rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            text: "›"

                            color: root.muted

                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: menuMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: {
                                if (modelData.action === "conf") {
                                    root.confOpen =
                                        !root.confOpen
                                } else {
                                    root.runMenuAction(
                                        modelData.action
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: confMenu

                visible: root.confOpen

                z: 101

                x: contextMenu.width - 2
                y: 6

                width: 230
                height: 228

                radius: 12

                color: root.bg

                border.color: root.bgLight
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 6

                    spacing: 2

                    Repeater {
                        model: [
                            {
                                label: "Quickshell",
                                key: "quickshell"
                            },
                            {
                                label: "Hyprland",
                                key: "hyprland"
                            },
                            {
                                label: "Hyprpaper",
                                key: "hyprpaper"
                            },
                            {
                                label: "Ghostty",
                                key: "ghostty"
                            },
                            {
                                label: "Starship",
                                key: "starship"
                            },
                            {
                                label: "Fastfetch",
                                key: "fastfetch"
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            width: parent.width
                            height: 34

                            radius: 7

                            color:
                                configMouse.containsMouse
                                ? root.bgDark
                                : "transparent"

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Open " + modelData.label + " Config"

                                color: root.text

                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: configMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: {
                                    root.openConfig(
                                        modelData.key
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

    Variants {
        model: Quickshell.screens

        PanelWindow {
    id: wallpaperPicker

    required property var modelData

    screen: modelData

    visible: root.wallpaperPickerOpen

    focusable: true

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    

    Item {
    id: wallpaperKeyboardFocus

    width: 1
    height: 1

    anchors {
        left: parent.left
        top: parent.top
    }

    TextInput {
        id: wallpaperKeyboardInput

        width: 1
        height: 1

        focus: root.wallpaperPickerOpen

        onTextChanged: {
            text = ""
        }

        Keys.onLeftPressed: {
            if (root.wallpapers.length === 0)
                return

            root.wallpaperIndex =
                (root.wallpaperIndex - 1 + root.wallpapers.length)
                % root.wallpapers.length
        }

        Keys.onRightPressed: {
            if (root.wallpapers.length === 0)
                return

            root.wallpaperIndex =
                (root.wallpaperIndex + 1)
                % root.wallpapers.length
        }

        Keys.onReturnPressed: {
            if (root.wallpapers.length === 0)
                return

            root.applyWallpaper(
                root.wallpapers[root.wallpaperIndex]
            )
        }

        Keys.onEscapePressed: {
            root.closeWallpaperPicker()
        }
    }
}

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.35
            }

            Rectangle {
    id: wallpaperPickerCard

    width: 900
    height: 360

    anchors.centerIn: parent

    color: root.bg
    radius: 18

    border.width: 1
    border.color: root.bgLight

    Row {
        anchors.centerIn: parent
        spacing: 18

        Repeater {
            model: root.wallpapers

            delegate: Rectangle {
                required property string modelData
                required property int index

                width: index === root.wallpaperIndex ? 520 : 150
                height: index === root.wallpaperIndex ? 292 : 220

                radius: 14

                color: root.bgDark

                border.width: index === root.wallpaperIndex ? 2 : 1
                border.color:
                    index === root.wallpaperIndex
                    ? root.blue
                    : root.bgLight

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Image {
                    anchors.fill: parent

                    source: "file://" + modelData

                    fillMode: Image.PreserveAspectCrop

                    asynchronous: true

                    smooth: true

                    clip: true

                    opacity:
                        index === root.wallpaperIndex
                        ? 1
                        : 0.55
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        root.wallpaperIndex = index
                    }
                }
            }
        }
    }

    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 16
        }

        text: "← / →   Select     Enter   Apply     Super+W   Close"

        color: root.muted
        font.pixelSize: 12
                }
            }
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true

        onTriggered: {
            weatherProcess.running = true
            updateProcess.running = true
        }
    }

    Component.onCompleted: {
    weatherProcess.running = true
    updateProcess.running = true
    wallpaperListProcess.running = true
}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 46
            color: "transparent"

            Rectangle {
                id: barBackground

                anchors {
                    fill: parent
                    leftMargin: 8
                    rightMargin: 8
                    topMargin: 6
                    bottomMargin: 2
                }

                radius: 12
                color: root.bg

                RowLayout {
                    id: leftSide

                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }

                    spacing: 8

                    Item {
                        width: 24
                        height: 24

                        Text {
                            anchors.centerIn: parent

                            text: "󰣚"
                            color: root.text
                            font.pixelSize: 20
                        }

                        Rectangle {
                            visible: root.updatesAvailable

                            width: 6
                            height: 6
                            radius: 3

                            anchors {
                                left: parent.left
                                top: parent.top
                            }

                            color: root.updateRed
                        }

                        MouseArea {
                            anchors.fill: parent

                            cursorShape:
                                root.updatesAvailable
                                ? Qt.PointingHandCursor
                                : Qt.ArrowCursor

                            onClicked: {
                                if (root.updatesAvailable &&
                                    !upgradeProcess.running) {
                                    root.updatesAvailable = false
                                    upgradeProcess.running = true
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: workspaceRow.implicitWidth + 18
                        implicitHeight: 30
                        radius: 15
                        color: root.bgDark

                        Row {
                            id: workspaceRow

                            anchors.centerIn: parent
                            spacing: 7

                            Repeater {
                                model: 5

                                Item {
                                    id: workspaceItem

                                    required property int index

                                    width: 22
                                    height: 22

                                    property var workspace:
                                        Hyprland.workspaces.values.find(
                                            ws => ws.id === index + 1
                                        )

                                    property bool active:
                                        Hyprland.focusedWorkspace &&
                                        Hyprland.focusedWorkspace.id === index + 1

                                    Rectangle {
                                        anchors.centerIn: parent

                                        width:
                                            workspaceItem.active
                                            ? 18
                                            : 7

                                        height:
                                            workspaceItem.active
                                            ? 18
                                            : 7

                                        radius: width / 2

                                        color:
                                            workspaceItem.active
                                            ? root.blue
                                            : root.muted

                                        Text {
                                            anchors.centerIn: parent

                                            visible:
                                                workspaceItem.active

                                            text:
                                                workspaceItem.index + 1

                                            color: root.text

                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent

                                        onClicked: {
                                            if (workspaceItem.workspace) {
                                                workspaceItem.workspace.activate()
                                            } else {
                                                Quickshell.execDetached([
                                                    "hyprctl",
                                                    "dispatch",
                                                    "workspace",
                                                    String(
                                                        workspaceItem.index + 1
                                                    )
                                                ])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.maximumWidth: 300

                        text: root.currentWorkspaceTitle()

                        color: root.muted
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: clockText

                    anchors.centerIn: parent

                    text:
                        Qt.formatTime(
                            new Date(),
                            "h:mmAP"
                        )

                    color: root.text
                    font.pixelSize: 15
                    font.bold: true

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true

                        onTriggered: {
                            clockText.text =
                                Qt.formatTime(
                                    new Date(),
                                    "h:mmAP"
                                )
                        }
                    }
                }

                RowLayout {
                    id: rightSide

                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }

                    spacing: 8

                    Rectangle {
                        id: mediaCapsule

                        property var spotifyPlayer:
                            root.activeSpotifyPlayer()

                        property var firefoxPlayer:
                            root.activeFirefoxPlayer()

                        property bool spotifyPlaying:
                            spotifyPlayer !== null

                        property bool firefoxPlaying:
                            !spotifyPlaying &&
                            firefoxPlayer !== null

                        property var activePlayer:
                            spotifyPlaying
                            ? spotifyPlayer
                            : firefoxPlayer

                        visible:
                            spotifyPlaying ||
                            firefoxPlaying

                        implicitHeight: 30

                        implicitWidth:
                            visible
                            ? mediaContent.implicitWidth + 24
                            : 0

                        radius: 15
                        color: root.bgDark

                        Behavior on implicitWidth {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        PwNodePeakMonitor {
                            id: audioPeakMonitor

                            node: Pipewire.defaultAudioSink
                            enabled: mediaCapsule.visible
                        }

                        Row {
                            id: mediaContent

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter

                                text:
                                    mediaCapsule.spotifyPlaying
                                    ? ""
                                    : ""

                                color: root.text
                                font.pixelSize: 17
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter

                                text:
                                    mediaCapsule.activePlayer
                                    ? (
                                        mediaCapsule.activePlayer.trackTitle
                                        ||
                                        mediaCapsule.activePlayer.identity
                                      )
                                    : ""

                                color: root.text
                                font.pixelSize: 11
                                font.bold: true

                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter

                                wrapMode: Text.NoWrap
                            }

                            Item {
                                id: waveform

                                width: 48
                                height: 20

                                anchors.verticalCenter: parent.verticalCenter

                                Canvas {
                                    id: waveCanvas

                                    anchors.fill: parent

                                    onPaint: {
                                        const ctx = getContext("2d")

                                        ctx.clearRect(
                                            0,
                                            0,
                                            width,
                                            height
                                        )

                                        ctx.beginPath()

                                        const centerY = height / 2

                                        const peak =
                                            Math.max(
                                                0,
                                                Math.min(
                                                    1,
                                                    audioPeakMonitor.peak
                                                )
                                            )

                                        const amplitude =
                                            peak < 0.015
                                            ? 0
                                            : 2 + peak * 7

                                        const phase =
                                            Date.now() / 180

                                        for (
                                            let x = 0;
                                            x <= width;
                                            x++
                                        ) {
                                            const progress =
                                                x / width

                                            const envelope =
                                                Math.sin(
                                                    progress *
                                                    Math.PI
                                                )

                                            const wave =
                                                Math.sin(
                                                    progress *
                                                    Math.PI *
                                                    4 +
                                                    phase
                                                ) *
                                                amplitude *
                                                envelope

                                            const y =
                                                centerY +
                                                wave

                                            if (x === 0)
                                                ctx.moveTo(x, y)
                                            else
                                                ctx.lineTo(x, y)
                                        }

                                        ctx.lineWidth = 2
                                        ctx.lineCap = "round"
                                        ctx.lineJoin = "round"
                                        ctx.strokeStyle = root.blue

                                        ctx.stroke()
                                    }
                                }

                                Connections {
                                    target: audioPeakMonitor

                                    function onPeakChanged() {
                                        waveCanvas.requestPaint()
                                    }
                                }

                                Timer {
                                    interval: 35
                                    running: mediaCapsule.visible
                                    repeat: true

                                    onTriggered: {
                                        waveCanvas.requestPaint()
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 5

                        Text {
                            text: root.weatherIcon
                            color: root.text
                            font.pixelSize: 18
                        }

                        Text {
                            text: root.weatherTemp
                            color: root.text
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        text:
                            Qt.formatDate(
                                new Date(),
                                "MM/dd/yyyy"
                            )

                        color: root.muted
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
