import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
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

    readonly property real submenuGap: 10

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


        /*
         * ============================================================
         * REUSABLE ANIMATED BORDER
         * ============================================================
         *
         * Dark center with a moving red / purple / blue / black
         * gradient around the outside.
         *
         * The animation only runs while the item is hovered.
         */

        Component {
    id: animatedHoverBorder

    Item {
        id: hoverBorder

        property bool active: false
        property real cornerRadius: 9
        property real borderWidth: 3.0

        anchors.fill: parent
        visible: active

        Canvas {
            id: borderCanvas

            anchors.fill: parent

            property real phase: 0

            NumberAnimation on phase {
                running: hoverBorder.active
                from: 0
                to: 1
                duration: 12000
                loops: Animation.Infinite
            }

            onPhaseChanged: requestPaint()

            function clamp(v, min, max) {
                return Math.max(min, Math.min(max, v))
            }

            function smooth(v) {
                v = clamp(v, 0, 1)
                return v * v * (3 - 2 * v)
            }

            function wrap(v) {
                v = v % 1
                if (v < 0)
                    v += 1
                return v
            }

            function mix(a, b, t) {
                t = smooth(t)

                return {
                    r: a.r + (b.r - a.r) * t,
                    g: a.g + (b.g - a.g) * t,
                    b: a.b + (b.b - a.b) * t
                }
            }

            /*
             * ====================================================
             * MOVING COLOR FIELD
             * ====================================================
             *
             * The field moves diagonally from:
             *
             *       TOP-LEFT
             *           ↖
             *             ↖
             *               ↖
             *                 ↖
             *              BOTTOM-RIGHT
             *
             * Unlike the old version, the colors aren't simply
             * placed in fixed blocks.
             *
             * The entire palette continuously shifts together.
             */

            function colorAt(x, y) {

    var w = Math.max(width, 1)
    var h = Math.max(height, 1)

    var nx = x / w
    var ny = y / h

    var diagonal =
        (nx + ny) * 0.5

    var p =
        wrap(diagonal + phase)

    /*
     * Stronger black / dark tones.
     */
    var black = {
        r: 0.004,
        g: 0.004,
        b: 0.008
    }

    var softBlack = {
        r: 0.018,
        g: 0.012,
        b: 0.030
    }

    var blackPurple = {
        r: 0.050,
        g: 0.012,
        b: 0.100
    }

    var purple = {
        r: 0.28,
        g: 0.035,
        b: 0.48
    }

    var vividPurple = {
        r: 0.42,
        g: 0.055,
        b: 0.65
    }

    var purpleBlue = {
        r: 0.22,
        g: 0.15,
        b: 0.60
    }

    var blue = {
        r: 0.055,
        g: 0.30,
        b: 0.68
    }

    var brightBlue = {
        r: 0.16,
        g: 0.52,
        b: 0.85
    }

    var paleBlue = {
        r: 0.55,
        g: 0.76,
        b: 0.91
    }

    var white = {
        r: 1.0,
        g: 1.0,
        b: 1.0
    }

    var c

    /*
     * Wider black sections.
     *
     * This makes black a real part of the moving pool instead
     * of just a tiny transition between purple and the edge.
     */

    if (p < 0.13) {

        c = mix(
            black,
            softBlack,
            p / 0.13
        )

    } else if (p < 0.22) {

        c = mix(
            softBlack,
            blackPurple,
            (p - 0.13) / 0.09
        )

    } else if (p < 0.32) {

        c = mix(
            blackPurple,
            purple,
            (p - 0.22) / 0.10
        )

    } else if (p < 0.42) {

        c = mix(
            purple,
            vividPurple,
            (p - 0.32) / 0.10
        )

    } else if (p < 0.52) {

        c = mix(
            vividPurple,
            purpleBlue,
            (p - 0.42) / 0.10
        )

    } else if (p < 0.62) {

        c = mix(
            purpleBlue,
            blue,
            (p - 0.52) / 0.10
        )

    } else if (p < 0.70) {

        c = mix(
            blue,
            brightBlue,
            (p - 0.62) / 0.08
        )

    } else if (p < 0.77) {

        c = mix(
            brightBlue,
            paleBlue,
            (p - 0.70) / 0.07
        )

    } else if (p < 0.84) {

        c = mix(
            paleBlue,
            white,
            (p - 0.77) / 0.07
        )

    } else if (p < 0.89) {

        c = mix(
            white,
            paleBlue,
            (p - 0.84) / 0.05
        )

    } else if (p < 0.94) {

        c = mix(
            paleBlue,
            purpleBlue,
            (p - 0.89) / 0.05
        )

    } else if (p < 0.975) {

        c = mix(
            purpleBlue,
            blackPurple,
            (p - 0.94) / 0.035
        )

    } else {

        c = mix(
            blackPurple,
            black,
            (p - 0.975) / 0.025
        )
    }

    /*
     * Keep the subtle color shifting.
     */
    var shift =
        Math.sin(
            (nx - ny) *
            Math.PI *
            2.4 +
            phase * Math.PI * 2
        )

    /*
     * Purple boost.
     */
    var purpleAmount =
        Math.max(
            0,
            shift
        )

    c.r +=
        purpleAmount * 0.035

    c.b +=
        purpleAmount * 0.042

    /*
     * Small blue movement.
     */
    var blueShift =
        Math.sin(
            (nx + ny) *
            Math.PI *
            3.0 -
            phase * Math.PI * 2
        )

    c.g +=
        blueShift * 0.012

    c.b +=
        blueShift * 0.018

    c.r =
        clamp(c.r, 0, 1)

    c.g =
        clamp(c.g, 0, 1)

    c.b =
        clamp(c.b, 0, 1)

    return c
}

            /*
             * ====================================================
             * DRAW BORDER SEGMENT
             * ====================================================
             */
            function drawSegment(
                ctx,
                x1,
                y1,
                x2,
                y2
            ) {

                var c1 =
                    colorAt(x1, y1)

                var c2 =
                    colorAt(x2, y2)

                /*
 * Perceived brightness.
 */
var brightness1 =
    c1.r * 0.2126 +
    c1.g * 0.7152 +
    c1.b * 0.0722

var brightness2 =
    c2.r * 0.2126 +
    c2.g * 0.7152 +
    c2.b * 0.0722

/*
 * Dark colors are now noticeably visible.
 *
 * Previously the minimum alpha was so low that black
 * basically disappeared.
 *
 * Now dark areas are subtle but clearly present.
 */
var alpha1 =
    0.12 +
    smooth(
        clamp(
            (brightness1 - 0.008) / 0.36,
            0,
            1
        )
    ) * 0.84

var alpha2 =
    0.12 +
    smooth(
        clamp(
            (brightness2 - 0.008) / 0.36,
            0,
            1
        )
    ) * 0.84

/*
 * Give purple a little extra visibility.
 */
var purpleAmount1 =
    clamp(
        (c1.r - c1.g) * 1.8,
        0,
        1
    )

var purpleAmount2 =
    clamp(
        (c2.r - c2.g) * 1.8,
        0,
        1
    )

alpha1 +=
    purpleAmount1 * 0.08

alpha2 +=
    purpleAmount2 * 0.08

alpha1 =
    clamp(alpha1, 0, 1)

alpha2 =
    clamp(alpha2, 0, 1)

                /*
                 * Middle color.
                 */
                var middleR =
                    (c1.r + c2.r) * 0.5

                var middleG =
                    (c1.g + c2.g) * 0.5

                var middleB =
                    (c1.b + c2.b) * 0.5

                var middleA =
                    (alpha1 + alpha2) * 0.5

                var gradient =
                    ctx.createLinearGradient(
                        x1,
                        y1,
                        x2,
                        y2
                    )

                gradient.addColorStop(
                    0,
                    Qt.rgba(
                        c1.r,
                        c1.g,
                        c1.b,
                        alpha1
                    )
                )

                gradient.addColorStop(
                    0.5,
                    Qt.rgba(
                        middleR,
                        middleG,
                        middleB,
                        middleA
                    )
                )

                gradient.addColorStop(
                    1,
                    Qt.rgba(
                        c2.r,
                        c2.g,
                        c2.b,
                        alpha2
                    )
                )

                ctx.beginPath()

                ctx.moveTo(
                    x1,
                    y1
                )

                ctx.lineTo(
                    x2,
                    y2
                )

                ctx.strokeStyle =
                    gradient

                ctx.lineWidth =
                    hoverBorder.borderWidth

                ctx.lineCap =
                    "butt"

                ctx.stroke()
            }

            onPaint: {

                var ctx =
                    getContext("2d")

                /*
                 * Completely transparent starting point.
                 *
                 * There is NO permanent border.
                 */
                ctx.clearRect(
                    0,
                    0,
                    width,
                    height
                )

                if (!hoverBorder.active)
                    return

                var inset =
                    hoverBorder.borderWidth / 2

                var w =
                    width -
                    hoverBorder.borderWidth

                var h =
                    height -
                    hoverBorder.borderWidth

                var radius =
                    Math.min(
                        hoverBorder.cornerRadius,
                        Math.min(w, h) / 2
                    )

                var sideSegments =
                    14

                var cornerSegments =
                    10

                /*
                 * =================================================
                 * TOP
                 * =================================================
                 */
                for (var i = 0;
                     i < sideSegments;
                     i++) {

                    var t1 =
                        i / sideSegments

                    var t2 =
                        (i + 1) / sideSegments

                    var x1 =
                        inset +
                        radius +
                        (w - radius * 2) * t1

                    var x2 =
                        inset +
                        radius +
                        (w - radius * 2) * t2

                    var y =
                        inset

                    drawSegment(
                        ctx,
                        x1,
                        y,
                        x2,
                        y
                    )
                }

                /*
                 * =================================================
                 * TOP-RIGHT CORNER
                 * =================================================
                 */
                for (var j = 0;
                     j < cornerSegments;
                     j++) {

                    var ct1 =
                        j / cornerSegments

                    var ct2 =
                        (j + 1) / cornerSegments

                    var a1 =
                        -Math.PI / 2 +
                        ct1 * Math.PI / 2

                    var a2 =
                        -Math.PI / 2 +
                        ct2 * Math.PI / 2

                    var x1c =
                        inset +
                        w -
                        radius +
                        Math.cos(a1) *
                        radius

                    var y1c =
                        inset +
                        radius +
                        Math.sin(a1) *
                        radius

                    var x2c =
                        inset +
                        w -
                        radius +
                        Math.cos(a2) *
                        radius

                    var y2c =
                        inset +
                        radius +
                        Math.sin(a2) *
                        radius

                    drawSegment(
                        ctx,
                        x1c,
                        y1c,
                        x2c,
                        y2c
                    )
                }

                /*
                 * =================================================
                 * RIGHT
                 * =================================================
                 */
                for (var k = 0;
                     k < sideSegments;
                     k++) {

                    var rt1 =
                        k / sideSegments

                    var rt2 =
                        (k + 1) / sideSegments

                    var y1r =
                        inset +
                        radius +
                        (h - radius * 2) *
                        rt1

                    var y2r =
                        inset +
                        radius +
                        (h - radius * 2) *
                        rt2

                    var x =
                        inset + w

                    drawSegment(
                        ctx,
                        x,
                        y1r,
                        x,
                        y2r
                    )
                }

                /*
                 * =================================================
                 * BOTTOM-RIGHT CORNER
                 * =================================================
                 */
                for (var m = 0;
                     m < cornerSegments;
                     m++) {

                    var bt1 =
                        m / cornerSegments

                    var bt2 =
                        (m + 1) /
                        cornerSegments

                    var ba1 =
                        bt1 *
                        Math.PI / 2

                    var ba2 =
                        bt2 *
                        Math.PI / 2

                    var bx1 =
                        inset +
                        w -
                        radius +
                        Math.cos(ba1) *
                        radius

                    var by1 =
                        inset +
                        h -
                        radius +
                        Math.sin(ba1) *
                        radius

                    var bx2 =
                        inset +
                        w -
                        radius +
                        Math.cos(ba2) *
                        radius

                    var by2 =
                        inset +
                        h -
                        radius +
                        Math.sin(ba2) *
                        radius

                    drawSegment(
                        ctx,
                        bx1,
                        by1,
                        bx2,
                        by2
                    )
                }

                /*
                 * =================================================
                 * BOTTOM
                 * =================================================
                 */
                for (var n = 0;
                     n < sideSegments;
                     n++) {

                    var bb1 =
                        n / sideSegments

                    var bb2 =
                        (n + 1) / sideSegments

                    var bxStart =
                        inset +
                        w -
                        radius -
                        (w - radius * 2) *
                        bb1

                    var bxEnd =
                        inset +
                        w -
                        radius -
                        (w - radius * 2) *
                        bb2

                    var by =
                        inset + h

                    drawSegment(
                        ctx,
                        bxStart,
                        by,
                        bxEnd,
                        by
                    )
                }

                /*
                 * =================================================
                 * BOTTOM-LEFT CORNER
                 * =================================================
                 */
                for (var q = 0;
                     q < cornerSegments;
                     q++) {

                    var bl1 =
                        q / cornerSegments

                    var bl2 =
                        (q + 1) /
                        cornerSegments

                    var bla1 =
                        Math.PI / 2 +
                        bl1 * Math.PI / 2

                    var bla2 =
                        Math.PI / 2 +
                        bl2 * Math.PI / 2

                    var xbl1 =
                        inset +
                        radius +
                        Math.cos(bla1) *
                        radius

                    var ybl1 =
                        inset +
                        h -
                        radius +
                        Math.sin(bla1) *
                        radius

                    var xbl2 =
                        inset +
                        radius +
                        Math.cos(bla2) *
                        radius

                    var ybl2 =
                        inset +
                        h -
                        radius +
                        Math.sin(bla2) *
                        radius

                    drawSegment(
                        ctx,
                        xbl1,
                        ybl1,
                        xbl2,
                        ybl2
                    )
                }

                /*
                 * =================================================
                 * LEFT
                 * =================================================
                 */
                for (var s = 0;
                     s < sideSegments;
                     s++) {

                    var lt1 =
                        s / sideSegments

                    var lt2 =
                        (s + 1) /
                        sideSegments

                    var ly1 =
                        inset +
                        h -
                        radius -
                        (h - radius * 2) *
                        lt1

                    var ly2 =
                        inset +
                        h -
                        radius -
                        (h - radius * 2) *
                        lt2

                    var lx =
                        inset

                    drawSegment(
                        ctx,
                        lx,
                        ly1,
                        lx,
                        ly2
                    )
                }

                /*
                 * =================================================
                 * TOP-LEFT CORNER
                 * =================================================
                 */
                for (var z = 0;
                     z < cornerSegments;
                     z++) {

                    var tl1 =
                        z / cornerSegments

                    var tl2 =
                        (z + 1) /
                        cornerSegments

                    var tla1 =
                        Math.PI +
                        tl1 * Math.PI / 2

                    var tla2 =
                        Math.PI +
                        tl2 * Math.PI / 2

                    var tx1 =
                        inset +
                        radius +
                        Math.cos(tla1) *
                        radius

                    var ty1 =
                        inset +
                        radius +
                        Math.sin(tla1) *
                        radius

                    var tx2 =
                        inset +
                        radius +
                        Math.cos(tla2) *
                        radius

                    var ty2 =
                        inset +
                        radius +
                        Math.sin(tla2) *
                        radius

                    drawSegment(
                        ctx,
                        tx1,
                        ty1,
                        tx2,
                        ty2
                    )
                }
            }
        }
    }
}


        /*
         * ============================================================
         * DESKTOP RIGHT CLICK AREA
         * ============================================================
         */

        MouseArea {

            anchors.fill: parent

            acceptedButtons:
                Qt.LeftButton | Qt.RightButton

            onClicked: function(mouse) {

                if (mouse.button === Qt.RightButton) {

                    root.menuX = mouse.x
                    root.menuY = mouse.y

                    root.menuOpen = true
                    root.confOpen = false

                    contextMenu.systemOpen = false
                    contextMenu.bluetoothOpen = false
                    contextMenu.networkOpen = false
                    contextMenu.displayOpen = false
                    contextMenu.audioOpen = false

                } else {

                    root.closeMenus()

                    contextMenu.systemOpen = false
                    contextMenu.bluetoothOpen = false
                    contextMenu.networkOpen = false
                    contextMenu.displayOpen = false
                    contextMenu.audioOpen = false
                }
            }
        }


        /*
         * ============================================================
         * MAIN MENU
         * ============================================================
         */

        Rectangle {

            id: contextMenu

            visible: root.menuOpen

            z: 100

            property bool systemOpen: false
            property bool bluetoothOpen: false
            property bool networkOpen: false
            property bool displayOpen: false
            property bool audioOpen: false

            property string powerMode: "Balanced"

            property int brightnessValue: 50

            property real volumeValue: 0.50

            property bool nightLightEnabled: false

            property bool wifiEnabled: true


            x: Math.min(
                root.menuX,
                parent.width - width - 10
            )

            y: Math.min(
                root.menuY,
                parent.height - height - 10
            )

            width: 250
            height: 360

            radius: 13

            color: root.bg

            border.color: root.bgLight
            border.width: 1


            /*
             * ========================================================
             * PROCESSES
             * ========================================================
             */

            Process {

                id: brightnessReadProcess

                command: [
                    "bash",
                    "-c",
                    "ddcutil getvcp 10 2>/dev/null | grep -oE '[0-9]+%' | head -1"
                ]

                stdout: StdioCollector {

                    onStreamFinished: {

                        let value =
                            parseInt(
                                text.replace(
                                    /[^0-9]/g,
                                    ""
                                )
                            )

                        if (!isNaN(value))
                            contextMenu.brightnessValue = value
                    }
                }
            }


            Process {

                id: brightnessDownProcess

                command: [
                    "ddcutil",
                    "setvcp",
                    "10",
                    "5-"
                ]
            }


            Process {

                id: brightnessUpProcess

                command: [
                    "ddcutil",
                    "setvcp",
                    "10",
                    "5+"
                ]
            }


            Process {

                id: volumeReadProcess

                command: [
                    "bash",
                    "-c",
                    "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'"
                ]

                stdout: StdioCollector {

                    onStreamFinished: {

                        let value =
                            parseInt(text.trim())

                        if (!isNaN(value))
                            contextMenu.volumeValue =
                                value / 100
                    }
                }
            }


            Process {

                id: volumeDownProcess

                command: [
                    "wpctl",
                    "set-volume",
                    "@DEFAULT_AUDIO_SINK@",
                    "5%-"
                ]
            }


            Process {

                id: volumeUpProcess

                command: [
                    "wpctl",
                    "set-volume",
                    "@DEFAULT_AUDIO_SINK@",
                    "5%+"
                ]
            }


            Process {

                id: muteProcess

                command: [
                    "wpctl",
                    "set-mute",
                    "@DEFAULT_AUDIO_SINK@",
                    "toggle"
                ]
            }


            Process {

                id: powerModeReadProcess

                command: [
                    "powerprofilesctl",
                    "get"
                ]

                stdout: StdioCollector {

                    onStreamFinished: {

                        let value = text.trim()

                        if (value === "performance") {

                            contextMenu.powerMode =
                                "Performance"

                        } else if (
                            value === "power-saver"
                        ) {

                            contextMenu.powerMode =
                                "Power Saver"

                        } else {

                            contextMenu.powerMode =
                                "Balanced"
                        }
                    }
                }
            }


            Process {
                id: powerModeSetProcess
            }


            Process {
                id: nightLightProcess
            }


            Process {
                id: wifiStateProcess

                command: [
                    "nmcli",
                    "radio",
                    "wifi"
                ]

                stdout: StdioCollector {

                    onStreamFinished: {

                        contextMenu.wifiEnabled =
                            text.trim() === "enabled"
                    }
                }
            }


            /*
             * ========================================================
             * SYSTEM FUNCTIONS
             * ========================================================
             */

            function refreshValues() {

                brightnessReadProcess.running = true

                volumeReadProcess.running = true

                powerModeReadProcess.running = true

                wifiStateProcess.running = true
            }


            function setPowerMode(mode) {

                contextMenu.powerMode = mode

                let value = "balanced"

                if (mode === "Performance")
                    value = "performance"

                if (mode === "Power Saver")
                    value = "power-saver"

                powerModeSetProcess.command = [
                    "powerprofilesctl",
                    "set",
                    value
                ]

                powerModeSetProcess.running = true
            }


            function changePowerMode(direction) {

                let modes = [
                    "Power Saver",
                    "Balanced",
                    "Performance"
                ]

                let current =
                    modes.indexOf(
                        contextMenu.powerMode
                    )

                if (current < 0)
                    current = 1

                current += direction

                if (current < 0)
                    current = modes.length - 1

                if (current >= modes.length)
                    current = 0

                setPowerMode(
                    modes[current]
                )
            }


            function openCommand(command) {

                let process =
                    Qt.createQmlObject(
                        'import Quickshell.Io; Process {}',
                        contextMenu
                    )

                process.command = [
                    "bash",
                    "-c",
                    command
                ]

                process.running = true
            }


            Component.onCompleted: {

                refreshValues()
            }


            /*
             * ========================================================
             * MAIN MENU
             * ========================================================
             */

            Column {

                anchors.fill: parent

                anchors.margins: 7

                spacing: 3


                Rectangle {

                    width: parent.width
                    height: 34

                    radius: 8

                    color:
                        terminalMouse.containsMouse
                        ? root.bgDark
                        : "transparent"

                    Text {

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        text: "Open Terminal"

                        color: root.text

                        font.pixelSize: 13
                    }

                    MouseArea {

                        id: terminalMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {

                            contextMenu.systemOpen = false
                            root.confOpen = false
                        }

                        onClicked:
                            root.runMenuAction("terminal")
                    }
                }


                Rectangle {

                    width: parent.width
                    height: 34

                    radius: 8

                    color:
                        filesMouse.containsMouse
                        ? root.bgDark
                        : "transparent"

                    Text {

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        text: "Open File Manager"

                        color: root.text

                        font.pixelSize: 13
                    }

                    MouseArea {

                        id: filesMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {

                            contextMenu.systemOpen = false
                            root.confOpen = false
                        }

                        onClicked:
                            root.runMenuAction("files")
                    }
                }


                Rectangle {

                    width: parent.width
                    height: 38

                    radius: 8

                    color:
                        systemMouse.containsMouse
                        ? root.bgDark
                        : "transparent"

                    Text {

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        text: "System Settings"

                        color: root.text

                        font.pixelSize: 13

                        font.bold: true
                    }

                    Text {

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

                        id: systemMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {

                            contextMenu.systemOpen = true

                            root.confOpen = false

                            contextMenu.bluetoothOpen = false
                            contextMenu.networkOpen = false
                            contextMenu.displayOpen = false
                            contextMenu.audioOpen = false

                            contextMenu.refreshValues()
                        }

                        onClicked: {

                            contextMenu.systemOpen =
                                !contextMenu.systemOpen

                            contextMenu.bluetoothOpen = false
                            contextMenu.networkOpen = false
                            contextMenu.displayOpen = false
                            contextMenu.audioOpen = false

                            contextMenu.refreshValues()
                        }
                    }
                }


                Rectangle {

                    width: parent.width
                    height: 34

                    radius: 8

                    color:
                        confMouse.containsMouse
                        ? root.bgDark
                        : "transparent"

                    Text {

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        text: "DebHypr Config"

                        color: root.text

                        font.pixelSize: 13
                    }

                    Text {

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

                        id: confMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {

                            root.confOpen = true

                            contextMenu.systemOpen = false
                            contextMenu.bluetoothOpen = false
                            contextMenu.networkOpen = false
                            contextMenu.displayOpen = false
                            contextMenu.audioOpen = false
                        }

                        onClicked: {

                            root.confOpen =
                                !root.confOpen

                            contextMenu.systemOpen = false
                        }
                    }
                }


                Rectangle {

                    width: parent.width
                    height: 34

                    radius: 8

                    color:
                        wallpaperMouse.containsMouse
                        ? root.bgDark
                        : "transparent"

                    Text {

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        text: "Wallpaper Picker"

                        color: root.text

                        font.pixelSize: 13
                    }

                    MouseArea {

                        id: wallpaperMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {

                            contextMenu.systemOpen = false
                            root.confOpen = false
                        }

                        onClicked: {

                            root.menuOpen = false

                            root.wallpaperPickerOpen = true
                        }
                    }
                }


                Rectangle {

                    width: parent.width
                    height: 34

                    radius: 8

                    color:
                        hyprReloadMouse.containsMouse
                        ? root.bgDark
                        : "transparent"

                    Text {

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        text: "Reload Hyprland"

                        color: root.text

                        font.pixelSize: 13
                    }

                    MouseArea {

                        id: hyprReloadMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {

                            contextMenu.systemOpen = false
                            root.confOpen = false
                        }

                        onClicked:
                            root.runMenuAction("hyprland")
                    }
                }


                Rectangle {

                    width: parent.width
                    height: 34

                    radius: 8

                    color:
                        windowsMouse.containsMouse
                        ? root.bgDark
                        : "transparent"

                    Text {

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        text: "Reboot to Windows"

                        color: root.text

                        font.pixelSize: 13
                    }

                    MouseArea {

                        id: windowsMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {

                            contextMenu.systemOpen = false
                            root.confOpen = false
                        }

                        onClicked:
                            root.runMenuAction("windows")
                    }
                }


                Rectangle {

                    width: parent.width
                    height: 34

                    radius: 8

                    color:
                        logoutMouse.containsMouse
                        ? root.bgDark
                        : "transparent"

                    Text {

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        text: "Log Out"

                        color: root.text

                        font.pixelSize: 13
                    }

                    MouseArea {

                        id: logoutMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {

                            contextMenu.systemOpen = false
                            root.confOpen = false
                        }

                        onClicked:
                            root.runMenuAction("logout")
                    }
                }
            }


            /*
             * ========================================================
             * SYSTEM SETTINGS PANEL
             * ========================================================
             */

            Rectangle {

                id: systemPanel

                visible:
                    contextMenu.systemOpen

                z: 200

                x: contextMenu.width + root.submenuGap

                y: 0

                width: 360

                height: 620

                radius: 13

                color: root.bg

                border.color: root.bgLight
                border.width: 1


                Flickable {

                    anchors.fill: parent

                    anchors.margins: 8

                    contentWidth: width

                    contentHeight:
                        systemColumn.height

                    clip: true


                    Column {

                        id: systemColumn

                        width: parent.width

                        spacing: 5


                        Text {

                            text: "DebHypr Control Center"

                            color: root.text

                            font.pixelSize: 15

                            font.bold: true

                            leftPadding: 8

                            topPadding: 5

                            bottomPadding: 6
                        }


                        /*
                         * POWER MODE
                         */

                        Rectangle {

                            width: parent.width
                            height: 52

                            radius: 9

                            color: root.bgDark


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Power Mode"

                                color: root.text

                                font.pixelSize: 12
                            }


                            Rectangle {

                                anchors {
                                    right: parent.right
                                    rightMargin: 7
                                    verticalCenter: parent.verticalCenter
                                }

                                width: 165
                                height: 34

                                radius: 9

                                color: root.bg


                                Text {

                                    anchors.centerIn: parent

                                    text:
                                        contextMenu.powerMode

                                    color: root.text

                                    font.pixelSize: 11

                                    font.bold: true
                                }


                                Rectangle {

                                    anchors.left: parent.left

                                    width: 38
                                    height: parent.height

                                    radius: 9

                                    color:
                                        powerLeftMouse.containsMouse
                                        ? root.bgLight
                                        : "transparent"

                                    Text {

                                        anchors.centerIn: parent

                                        text: "‹"

                                        color: root.text

                                        font.pixelSize: 22
                                    }

                                    MouseArea {

                                        id: powerLeftMouse

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onClicked:
                                            contextMenu.changePowerMode(-1)
                                    }
                                }


                                Rectangle {

                                    anchors.right: parent.right

                                    width: 38
                                    height: parent.height

                                    radius: 9

                                    color:
                                        powerRightMouse.containsMouse
                                        ? root.bgLight
                                        : "transparent"

                                    Text {

                                        anchors.centerIn: parent

                                        text: "›"

                                        color: root.text

                                        font.pixelSize: 22
                                    }

                                    MouseArea {

                                        id: powerRightMouse

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onClicked:
                                            contextMenu.changePowerMode(1)
                                    }
                                }
                            }
                        }


                        /*
                         * BRIGHTNESS
                         */

                        Rectangle {

                            width: parent.width
                            height: 48

                            radius: 9

                            color: "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Brightness"

                                color: root.text

                                font.pixelSize: 12
                            }


                            Rectangle {

                                anchors {
                                    right: parent.right
                                    rightMargin: 7
                                    verticalCenter: parent.verticalCenter
                                }

                                width: 165
                                height: 34

                                radius: 9

                                color: root.bgDark


                                Rectangle {

                                    anchors.left: parent.left

                                    width: 40
                                    height: parent.height

                                    radius: 9

                                    color:
                                        brightnessDownMouse.containsMouse
                                        ? root.bgLight
                                        : "transparent"

                                    Text {

                                        anchors.centerIn: parent

                                        text: "−"

                                        color: root.text

                                        font.pixelSize: 18
                                    }

                                    MouseArea {

                                        id: brightnessDownMouse

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onClicked: {

                                            brightnessDownProcess.running =
                                                true

                                            brightnessReadProcess.running =
                                                true
                                        }
                                    }
                                }


                                Text {

                                    anchors.centerIn: parent

                                    text:
                                        contextMenu.brightnessValue
                                        + "%"

                                    color: root.text

                                    font.pixelSize: 11

                                    font.bold: true
                                }


                                Rectangle {

                                    anchors.right: parent.right

                                    width: 40
                                    height: parent.height

                                    radius: 9

                                    color:
                                        brightnessUpMouse.containsMouse
                                        ? root.bgLight
                                        : "transparent"

                                    Text {

                                        anchors.centerIn: parent

                                        text: "+"

                                        color: root.text

                                        font.pixelSize: 18
                                    }

                                    MouseArea {

                                        id: brightnessUpMouse

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onClicked: {

                                            brightnessUpProcess.running =
                                                true

                                            brightnessReadProcess.running =
                                                true
                                        }
                                    }
                                }
                            }
                        }


                        /*
                         * VOLUME
                         */

                        Rectangle {

                            width: parent.width
                            height: 48

                            radius: 9

                            color: "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Volume"

                                color: root.text

                                font.pixelSize: 12
                            }


                            Rectangle {

                                anchors {
                                    right: parent.right
                                    rightMargin: 7
                                    verticalCenter: parent.verticalCenter
                                }

                                width: 165
                                height: 34

                                radius: 9

                                color: root.bgDark


                                Rectangle {

                                    anchors.left: parent.left

                                    width: 40
                                    height: parent.height

                                    radius: 9

                                    color:
                                        volumeDownMouse.containsMouse
                                        ? root.bgLight
                                        : "transparent"

                                    Text {

                                        anchors.centerIn: parent

                                        text: "−"

                                        color: root.text

                                        font.pixelSize: 18
                                    }

                                    MouseArea {

                                        id: volumeDownMouse

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onClicked: {

                                            volumeDownProcess.running =
                                                true

                                            volumeReadProcess.running =
                                                true
                                        }
                                    }
                                }


                                Text {

                                    anchors.centerIn: parent

                                    text:
                                        Math.round(
                                            contextMenu.volumeValue * 100
                                        )
                                        + "%"

                                    color: root.text

                                    font.pixelSize: 11

                                    font.bold: true
                                }


                                Rectangle {

                                    anchors.right: parent.right

                                    width: 40
                                    height: parent.height

                                    radius: 9

                                    color:
                                        volumeUpMouse.containsMouse
                                        ? root.bgLight
                                        : "transparent"

                                    Text {

                                        anchors.centerIn: parent

                                        text: "+"

                                        color: root.text

                                        font.pixelSize: 18
                                    }

                                    MouseArea {

                                        id: volumeUpMouse

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onClicked: {

                                            volumeUpProcess.running =
                                                true

                                            volumeReadProcess.running =
                                                true
                                        }
                                    }
                                }
                            }
                        }


                        /*
                         * NIGHT LIGHT
                         */

                        Rectangle {

                            width: parent.width
                            height: 42

                            radius: 9

                            color:
                                nightLightMouse.containsMouse
                                ? root.bgDark
                                : "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Night Light"

                                color: root.text

                                font.pixelSize: 12
                            }


                            Rectangle {

                                anchors {
                                    right: parent.right
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }

                                width: 50
                                height: 28

                                radius: 14

                                color:
                                    contextMenu.nightLightEnabled
                                    ? root.blue
                                    : root.bgLight


                                Rectangle {

                                    width: 22
                                    height: 22

                                    radius: 11

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    x:
                                        contextMenu.nightLightEnabled
                                        ? parent.width - width - 3
                                        : 3

                                    color: root.text
                                }


                                MouseArea {

                                    id: nightLightMouse

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    onEntered: {

                                        contextMenu.bluetoothOpen = false
                                        contextMenu.networkOpen = false
                                        contextMenu.displayOpen = false
                                        contextMenu.audioOpen = false
                                    }

                                    onClicked: {

                                        contextMenu.nightLightEnabled =
                                            !contextMenu.nightLightEnabled

                                        if (
                                            contextMenu.nightLightEnabled
                                        ) {

                                            nightLightProcess.command = [
                                                "hyprsunset",
                                                "-t",
                                                "4500"
                                            ]

                                        } else {

                                            nightLightProcess.command = [
                                                "pkill",
                                                "hyprsunset"
                                            ]
                                        }

                                        nightLightProcess.running =
                                            true
                                    }
                                }
                            }
                        }


                        /*
                         * SECTION
                         */

                        Text {

                            text: "Devices"

                            color: root.muted

                            font.pixelSize: 10

                            leftPadding: 10

                            topPadding: 7
                        }


                        /*
                         * BLUETOOTH
                         */

                        Rectangle {

                            width: parent.width
                            height: 44

                            radius: 9

                            color:
                                bluetoothMouse.containsMouse
                                ? root.bgDark
                                : "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Bluetooth"

                                color: root.text

                                font.pixelSize: 12
                            }


                            Text {

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

                                id: bluetoothMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.bluetoothOpen = true

                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }

                                onClicked: {

                                    contextMenu.bluetoothOpen =
                                        !contextMenu.bluetoothOpen

                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }
                            }
                        }


                        /*
                         * NETWORK
                         */

                        Rectangle {

                            width: parent.width
                            height: 44

                            radius: 9

                            color:
                                networkMouse.containsMouse
                                ? root.bgDark
                                : "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Wi-Fi / Network"

                                color: root.text

                                font.pixelSize: 12
                            }


                            Text {

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

                                id: networkMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.networkOpen = true

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }

                                onClicked: {

                                    contextMenu.networkOpen =
                                        !contextMenu.networkOpen

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }
                            }
                        }


                        /*
                         * DISPLAY
                         */

                        Rectangle {

                            width: parent.width
                            height: 44

                            radius: 9

                            color:
                                displayMouse.containsMouse
                                ? root.bgDark
                                : "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Display"

                                color: root.text

                                font.pixelSize: 12
                            }


                            Text {

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

                                id: displayMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.displayOpen = true

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.audioOpen = false
                                }

                                onClicked: {

                                    contextMenu.displayOpen =
                                        !contextMenu.displayOpen

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.audioOpen = false
                                }
                            }
                        }


                        /*
                         * AUDIO
                         */

                        Rectangle {

                            width: parent.width
                            height: 44

                            radius: 9

                            color:
                                audioMouse.containsMouse
                                ? root.bgDark
                                : "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Audio Devices"

                                color: root.text

                                font.pixelSize: 12
                            }


                            Text {

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

                                id: audioMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.audioOpen = true

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                }

                                onClicked: {

                                    contextMenu.audioOpen =
                                        !contextMenu.audioOpen

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                }
                            }
                        }


                        /*
                         * SYSTEM
                         */

                        Text {

                            text: "System"

                            color: root.muted

                            font.pixelSize: 10

                            leftPadding: 10

                            topPadding: 7
                        }


                        /*
                         * APPEARANCE
                         */

                        Rectangle {

                            width: parent.width
                            height: 42

                            radius: 9

                            color:
                                appearanceMouse.containsMouse
                                ? root.bgDark
                                : "transparent"

                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Appearance"

                                color: root.text

                                font.pixelSize: 12
                            }

                            MouseArea {

                                id: appearanceMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }

                                onClicked:
                                    contextMenu.openCommand(
                                        "systemsettings kcm_lookandfeel"
                                    )
                            }
                        }


                        /*
                         * NOTIFICATIONS
                         */

                        Rectangle {

                            width: parent.width
                            height: 42

                            radius: 9

                            color:
                                notificationsMouse.containsMouse
                                ? root.bgDark
                                : "transparent"

                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Notifications"

                                color: root.text

                                font.pixelSize: 12
                            }

                            MouseArea {

                                id: notificationsMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }

                                onClicked:
                                    contextMenu.openCommand(
                                        "systemsettings kcm_notifications"
                                    )
                            }
                        }


                        /*
                         * POWER
                         */

                        Rectangle {

                            width: parent.width
                            height: 42

                            radius: 9

                            color:
                                powerSettingsMouse.containsMouse
                                ? root.bgDark
                                : "transparent"

                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Power Management"

                                color: root.text

                                font.pixelSize: 12
                            }

                            MouseArea {

                                id: powerSettingsMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }

                                onClicked:
                                    contextMenu.openCommand(
                                        "systemsettings kcm_powerdevilprofilesconfig"
                                    )
                            }
                        }


                        /*
                         * KEYBOARD / MOUSE
                         */

                        Row {

                            width: parent.width

                            height: 40

                            spacing: 4


                            Rectangle {

                                width:
                                    (parent.width - 4) / 2

                                height: 38

                                radius: 8

                                color:
                                    keyboardMouse.containsMouse
                                    ? root.bgDark
                                    : "transparent"

                                Text {

                                    anchors.centerIn: parent

                                    text: "Keyboard"

                                    color: root.text

                                    font.pixelSize: 11
                                }

                                MouseArea {

                                    id: keyboardMouse

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    onEntered: {

                                        contextMenu.bluetoothOpen = false
                                        contextMenu.networkOpen = false
                                        contextMenu.displayOpen = false
                                        contextMenu.audioOpen = false
                                    }

                                    onClicked:
                                        contextMenu.openCommand(
                                            "systemsettings kcm_keyboard"
                                        )
                                }
                            }


                            Rectangle {

                                width:
                                    (parent.width - 4) / 2

                                height: 38

                                radius: 8

                                color:
                                    mouseMouse.containsMouse
                                    ? root.bgDark
                                    : "transparent"

                                Text {

                                    anchors.centerIn: parent

                                    text: "Mouse"

                                    color: root.text

                                    font.pixelSize: 11
                                }

                                MouseArea {

                                    id: mouseMouse

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    onEntered: {

                                        contextMenu.bluetoothOpen = false
                                        contextMenu.networkOpen = false
                                        contextMenu.displayOpen = false
                                        contextMenu.audioOpen = false
                                    }

                                    onClicked:
                                        contextMenu.openCommand(
                                            "systemsettings kcm_mouse"
                                        )
                                }
                            }
                        }


                        /*
                         * HYPRLAND
                         */

                        Rectangle {

                            width: parent.width

                            height: 42

                            radius: 9

                            color:
                                hyprlandSettingsMouse.containsMouse
                                ? root.bgDark
                                : "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Hyprland Settings"

                                color: root.text

                                font.pixelSize: 12
                            }


                            MouseArea {

                                id: hyprlandSettingsMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }

                                onClicked:
                                    root.runMenuAction("hyprland")
                            }
                        }


                        /*
                         * QUICKSHELL
                         */

                        Rectangle {

                            width: parent.width

                            height: 42

                            radius: 9

                            color:
                                quickshellSettingsMouse.containsMouse
                                ? root.bgDark
                                : "transparent"


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text: "Reload Quickshell"

                                color: root.text

                                font.pixelSize: 12
                            }


                            MouseArea {

                                id: quickshellSettingsMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {

                                    contextMenu.bluetoothOpen = false
                                    contextMenu.networkOpen = false
                                    contextMenu.displayOpen = false
                                    contextMenu.audioOpen = false
                                }

                                onClicked:
                                    root.runMenuAction("quickshell")
                            }
                        }
                    }
                }
            }


            /*
             * ========================================================
             * BLUETOOTH PANEL
             * ========================================================
             */

            Rectangle {

                id: bluetoothPanel

                visible:
                    contextMenu.bluetoothOpen

                z: 300

                x:
                    contextMenu.width
                    + systemPanel.width
                    + root.submenuGap

                y: 0

                width: 350
                height: 620

                radius: 13

                color: root.bg

                border.color: root.bgLight
                border.width: 1


                Column {

                    anchors.fill: parent

                    anchors.margins: 9

                    spacing: 6


                    Text {

                        text: "Bluetooth"

                        color: root.text

                        font.pixelSize: 15

                        font.bold: true
                    }


                    Rectangle {

                        width: parent.width

                        height: 48

                        radius: 9

                        color: root.bgDark


                        Text {

                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            text: "Bluetooth"

                            color: root.text

                            font.pixelSize: 12
                        }


                        Rectangle {

                            anchors {
                                right: parent.right
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }

                            width: 52
                            height: 28

                            radius: 14

                            color:
                                Bluetooth.defaultAdapter &&
                                Bluetooth.defaultAdapter.enabled
                                ? root.blue
                                : root.bgLight


                            Rectangle {

                                width: 22
                                height: 22

                                radius: 11

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                x:
                                    Bluetooth.defaultAdapter &&
                                    Bluetooth.defaultAdapter.enabled
                                    ? parent.width - width - 3
                                    : 3

                                color: root.text
                            }


                            MouseArea {

                                anchors.fill: parent

                                onClicked: {

                                    if (
                                        Bluetooth.defaultAdapter
                                    ) {

                                        Bluetooth.defaultAdapter.enabled =
                                            !Bluetooth.defaultAdapter.enabled
                                    }
                                }
                            }
                        }
                    }


                    Rectangle {

                        width: parent.width

                        height: 38

                        radius: 8

                        color:
                            scanBluetoothMouse.containsMouse
                            ? root.bgDark
                            : "transparent"


                        Text {

                            anchors.centerIn: parent

                            text:
                                Bluetooth.defaultAdapter &&
                                Bluetooth.defaultAdapter.discovering
                                ? "Scanning..."
                                : "Scan for Devices"

                            color: root.text

                            font.pixelSize: 11
                        }


                        MouseArea {

                            id: scanBluetoothMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: {

                                if (
                                    Bluetooth.defaultAdapter
                                ) {

                                    Bluetooth.defaultAdapter.discovering =
                                        true
                                }
                            }
                        }
                    }


                    Text {

                        text: "Devices"

                        color: root.muted

                        font.pixelSize: 10

                        topPadding: 5
                    }


                    Flickable {

                        width: parent.width

                        height: 480

                        contentWidth: width

                        contentHeight:
                            bluetoothDevicesColumn.height

                        clip: true


                        Column {

                            id: bluetoothDevicesColumn

                            width: parent.width

                            spacing: 5


                            Repeater {

                                model:
                                    Bluetooth.defaultAdapter
                                    ? Bluetooth.defaultAdapter.devices
                                    : null


                                delegate: Rectangle {

                                    id: bluetoothDeviceCard

                                    required property var modelData

                                    width: parent.width

                                    height: 60

                                    radius: 9

                                    color:
                                        modelData.connected
                                        ? root.bgLight
                                        : (
                                            modelData.paired
                                            ? root.bgDark
                                            : root.bgDark
                                        )

                                    border.width:
                                        modelData.connected
                                        ? 1
                                        : 0

                                    border.color:
                                        root.bgLight


                                    /*
                                     * ANIMATED HOVER BORDER
                                     */

                                    Loader {

                                        anchors.fill: parent

                                        sourceComponent:
                                            animatedHoverBorder

                                        property bool hovered:
                                            bluetoothDeviceMouse.containsMouse

                                        onLoaded: {

                                            item.active =
                                                Qt.binding(
                                                    function() {
                                                        return hovered
                                                    }
                                                )
                                        }
                                    }


                                    Text {

                                        anchors {
                                            left: parent.left
                                            leftMargin: 10
                                            top: parent.top
                                            topMargin: 8
                                            right: forgetBluetoothMouse.visible
                                                ? forgetBluetoothMouse.parent.left
                                                : parent.right
                                            rightMargin: 45
                                        }

                                        text:
                                            modelData.name !== ""
                                            ? modelData.name
                                            : modelData.address

                                        color: root.text

                                        font.pixelSize: 11

                                        font.bold:
                                            modelData.connected
                                    }


                                    Text {

                                        anchors {
                                            left: parent.left
                                            leftMargin: 10
                                            bottom: parent.bottom
                                            bottomMargin: 8
                                        }

                                        text:
                                            modelData.connected
                                            ? (
                                                modelData.batteryAvailable
                                                ? "Connected • "
                                                  + Math.round(
                                                      modelData.battery * 100
                                                  )
                                                  + "%"
                                                : "Connected"
                                            )
                                            : (
                                                modelData.paired
                                                ? "Paired"
                                                : "Available"
                                            )

                                        color: root.muted

                                        font.pixelSize: 9
                                    }


                                    MouseArea {

                                        id: bluetoothDeviceMouse

                                        anchors.fill: parent

                                        anchors.rightMargin: 48

                                        hoverEnabled: true

                                        onClicked: {

                                            if (
                                                modelData.connected
                                            ) {

                                                modelData.disconnect()

                                            } else if (
                                                modelData.paired
                                            ) {

                                                modelData.connect()

                                            } else {

                                                modelData.pair()
                                            }
                                        }
                                    }


                                    Rectangle {

                                        anchors {
                                            right: parent.right
                                            rightMargin: 7
                                            verticalCenter: parent.verticalCenter
                                        }

                                        width: 32
                                        height: 32

                                        radius: 8

                                        visible:
                                            modelData.paired


                                        color:
                                            forgetBluetoothMouse.containsMouse
                                            ? root.bgLight
                                            : "transparent"


                                        Text {

                                            anchors.centerIn: parent

                                            text: "×"

                                            color: root.muted

                                            font.pixelSize: 18
                                        }


                                        MouseArea {

                                            id: forgetBluetoothMouse

                                            anchors.fill: parent

                                            hoverEnabled: true

                                            onClicked:
                                                modelData.forget()
                                        }
                                    }
                                }
                            }


                            Text {

                                visible:
                                    bluetoothDevicesColumn.children.length
                                    <= 1

                                text:
                                    "No Bluetooth devices found."

                                color: root.muted

                                font.pixelSize: 10

                                padding: 10
                            }
                        }
                    }
                }
            }


            /*
             * ========================================================
             * NETWORK PANEL
             * ========================================================
             */

            Rectangle {

                id: networkPanel

                visible:
                    contextMenu.networkOpen

                z: 300

                x:
                    contextMenu.width
                    + systemPanel.width
                    + root.submenuGap

                y: 0

                width: 370
                height: 620

                radius: 13

                color: root.bg

                border.color: root.bgLight
                border.width: 1


                Process {

                    id: wifiListProcess

                    command: [
                        "bash",
                        "-c",
                        "nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list --rescan yes"
                    ]

                    stdout: StdioCollector {

                        onStreamFinished: {

                            wifiModel.clear()

                            let lines =
                                text.trim().split("\n")

                            for (
                                let i = 0;
                                i < lines.length;
                                i++
                            ) {

                                if (
                                    lines[i].trim() === ""
                                )
                                    continue

                                let parts =
                                    lines[i].split(":")

                                if (
                                    parts.length < 4
                                )
                                    continue

                                wifiModel.append({

                                    active:
                                        parts[0] === "*",

                                    name:
                                        parts[1] === ""
                                        ? "Hidden Network"
                                        : parts[1],

                                    security:
                                        parts[2],

                                    signal:
                                        parts[3]
                                })
                            }
                        }
                    }
                }


                ListModel {
                    id: wifiModel
                }


                Process {
                    id: wifiToggleProcess
                }


                Process {
                    id: wifiConnectProcess
                }


                Column {

                    anchors.fill: parent

                    anchors.margins: 9

                    spacing: 5


                    Text {

                        text: "Wi-Fi / Network"

                        color: root.text

                        font.pixelSize: 15

                        font.bold: true
                    }


                    Rectangle {

                        width: parent.width

                        height: 48

                        radius: 9

                        color: root.bgDark


                        Text {

                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            text: "Wi-Fi"

                            color: root.text

                            font.pixelSize: 12
                        }


                        Rectangle {

                            anchors {
                                right: parent.right
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }

                            width: 52
                            height: 28

                            radius: 14

                            color:
                                contextMenu.wifiEnabled
                                ? root.blue
                                : root.bgLight


                            Rectangle {

                                width: 22
                                height: 22

                                radius: 11

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                x:
                                    contextMenu.wifiEnabled
                                    ? parent.width - width - 3
                                    : 3

                                color: root.text
                            }


                            MouseArea {

                                anchors.fill: parent

                                onClicked: {

                                    wifiToggleProcess.command = [
                                        "nmcli",
                                        "radio",
                                        "wifi",
                                        contextMenu.wifiEnabled
                                        ? "off"
                                        : "on"
                                    ]

                                    wifiToggleProcess.running = true

                                    contextMenu.wifiEnabled =
                                        !contextMenu.wifiEnabled

                                    wifiListProcess.running =
                                        contextMenu.wifiEnabled
                                }
                            }
                        }
                    }


                    Text {

                        text:
                            contextMenu.wifiEnabled
                            ? "Available networks"
                            : "Wi-Fi is disabled"

                        color: root.muted

                        font.pixelSize: 10

                        padding: 4
                    }


                    Flickable {

                        width: parent.width

                        height: 475

                        contentWidth: width

                        contentHeight:
                            wifiListColumn.height

                        clip: true


                        Column {

                            id: wifiListColumn

                            width: parent.width

                            spacing: 5


                            Repeater {

                                model: wifiModel


                                delegate: Rectangle {

                                    id: wifiCard

                                    required property var modelData

                                    width: parent.width

                                    height: 54

                                    radius: 9

                                    color:
                                        modelData.active
                                        ? root.bgLight
                                        : root.bgDark


                                    Loader {

                                        anchors.fill: parent

                                        sourceComponent:
                                            animatedHoverBorder

                                        property bool hovered:
                                            wifiMouse.containsMouse

                                        onLoaded: {

                                            item.active =
                                                Qt.binding(
                                                    function() {
                                                        return hovered
                                                    }
                                                )
                                        }
                                    }


                                    Text {

                                        anchors {
                                            left: parent.left
                                            leftMargin: 10
                                            top: parent.top
                                            topMargin: 7
                                            right: parent.right
                                            rightMargin: 10
                                        }

                                        text:
                                            modelData.name

                                        color: root.text

                                        font.pixelSize: 11

                                        font.bold:
                                            modelData.active
                                    }


                                    Text {

                                        anchors {
                                            left: parent.left
                                            leftMargin: 10
                                            bottom: parent.bottom
                                            bottomMargin: 7
                                        }

                                        text:
                                            (
                                                modelData.active
                                                ? "Connected • "
                                                : ""
                                            )
                                            +
                                            (
                                                modelData.security === ""
                                                ? "Open"
                                                : modelData.security
                                            )
                                            +
                                            " • "
                                            +
                                            modelData.signal
                                            +
                                            "%"

                                        color: root.muted

                                        font.pixelSize: 9
                                    }


                                    MouseArea {

                                        id: wifiMouse

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onClicked: {

                                            if (
                                                modelData.active
                                            ) {

                                                wifiConnectProcess.command = [
                                                    "nmcli",
                                                    "connection",
                                                    "down",
                                                    modelData.name
                                                ]

                                            } else {

                                                wifiConnectProcess.command = [
                                                    "bash",
                                                    "-c",
                                                    "nmcli connection show | grep -F -- \"$1\" >/dev/null 2>&1 && nmcli connection up \"$1\" || nm-connection-editor",
                                                    "wifi",
                                                    modelData.name
                                                ]
                                            }

                                            wifiConnectProcess.running =
                                                true
                                        }
                                    }
                                }
                            }
                        }
                    }


                    Rectangle {

                        width: parent.width

                        height: 36

                        radius: 8

                        color:
                            wifiRefreshMouse.containsMouse
                            ? root.bgLight
                            : root.bgDark


                        Text {

                            anchors.centerIn: parent

                            text: "Scan Again"

                            color: root.text

                            font.pixelSize: 10
                        }


                        MouseArea {

                            id: wifiRefreshMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked:
                                wifiListProcess.running = true
                        }
                    }
                }


                Component.onCompleted:
                    wifiListProcess.running = true
            }


            /*
             * ========================================================
             * DISPLAY PANEL
             * ========================================================
             */

            Rectangle {

                id: displayPanel

                visible:
                    contextMenu.displayOpen

                z: 300

                x:
                    contextMenu.width
                    + systemPanel.width
                    + root.submenuGap

                y: 0

                width: 380
                height: 620

                radius: 13

                color: root.bg

                border.color: root.bgLight
                border.width: 1


                Process {

                    id: monitorInfoProcess

                    command: [
                        "hyprctl",
                        "monitors"
                    ]

                    stdout: StdioCollector {
                        id: monitorInfoOutput
                    }
                }


                Process {
                    id: displaySettingsProcess
                }


                Column {

                    anchors.fill: parent

                    anchors.margins: 10

                    spacing: 7


                    Text {

                        text: "Display"

                        color: root.text

                        font.pixelSize: 15

                        font.bold: true
                    }


                    Rectangle {

                        width: parent.width

                        height: 110

                        radius: 9

                        color: root.bgDark


                        Text {

                            anchors {
                                fill: parent
                                margins: 10
                            }

                            text:
                                monitorInfoOutput.text === ""
                                ? "Reading monitor information..."
                                : monitorInfoOutput.text

                            color: root.text

                            font.pixelSize: 10

                            wrapMode: Text.Wrap
                        }
                    }


                    Rectangle {

                        width: parent.width

                        height: 42

                        radius: 9

                        color:
                            displaySettingsMouse.containsMouse
                            ? root.bgLight
                            : root.bgDark


                        Text {

                            anchors.centerIn: parent

                            text:
                                "Open Advanced Display Settings"

                            color: root.text

                            font.pixelSize: 11
                        }


                        MouseArea {

                            id: displaySettingsMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: {

                                displaySettingsProcess.command = [
                                    "bash",
                                    "-c",
                                    "systemsettings kcm_kscreen || true"
                                ]

                                displaySettingsProcess.running = true
                            }
                        }
                    }


                    Rectangle {

                        width: parent.width

                        height: 42

                        radius: 9

                        color:
                            displayReloadMouse.containsMouse
                            ? root.bgLight
                            : root.bgDark


                        Text {

                            anchors.centerIn: parent

                            text:
                                "Refresh Monitor Information"

                            color: root.text

                            font.pixelSize: 11
                        }


                        MouseArea {

                            id: displayReloadMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked:
                                monitorInfoProcess.running = true
                        }
                    }
                }


                Component.onCompleted:
                    monitorInfoProcess.running = true
            }


            /*
             * ========================================================
             * AUDIO PANEL
             * ========================================================
             */

            Rectangle {

                id: audioPanel

                visible:
                    contextMenu.audioOpen

                z: 300

                x:
                    contextMenu.width
                    + systemPanel.width
                    + root.submenuGap

                y: 0

                width: 380
                height: 620

                radius: 13

                color: root.bg

                border.color: root.bgLight
                border.width: 1


                Column {

                    anchors.fill: parent

                    anchors.margins: 10

                    spacing: 5


                    Text {

                        text: "Audio Devices"

                        color: root.text

                        font.pixelSize: 15

                        font.bold: true
                    }


                    Rectangle {

                        width: parent.width

                        height: 44

                        radius: 9

                        color: root.bgDark


                        Text {

                            anchors {
                                fill: parent
                                margins: 10
                            }

                            text:
                                Pipewire.defaultAudioSink
                                ? (
                                    "Output: "
                                    +
                                    (
                                        Pipewire.defaultAudioSink.description
                                        !== ""
                                        ? Pipewire.defaultAudioSink.description
                                        : Pipewire.defaultAudioSink.name
                                    )
                                )
                                : "Output: None"

                            color: root.text

                            font.pixelSize: 10

                            wrapMode: Text.Wrap
                        }
                    }


                    Rectangle {

                        width: parent.width

                        height: 44

                        radius: 9

                        color: root.bgDark


                        Text {

                            anchors {
                                fill: parent
                                margins: 10
                            }

                            text:
                                Pipewire.defaultAudioSource
                                ? (
                                    "Input: "
                                    +
                                    (
                                        Pipewire.defaultAudioSource.description
                                        !== ""
                                        ? Pipewire.defaultAudioSource.description
                                        : Pipewire.defaultAudioSource.name
                                    )
                                )
                                : "Input: None"

                            color: root.text

                            font.pixelSize: 10

                            wrapMode: Text.Wrap
                        }
                    }


                    Text {

                        text: "Available Audio Devices"

                        color: root.muted

                        font.pixelSize: 10

                        topPadding: 6
                    }


                    Flickable {

                        width: parent.width

                        height: 440

                        contentWidth: width

                        contentHeight:
                            audioColumn.height

                        clip: true


                        Column {

                            id: audioColumn

                            width: parent.width

                            spacing: 5


                            Repeater {

                                model:
                                    Pipewire.nodes


                                delegate: Rectangle {

                                    id: audioCard

                                    required property var modelData

                                    visible:
                                        modelData.audio !== null &&
                                        !modelData.isStream

                                    width: parent.width

                                    height:
                                        visible
                                        ? 50
                                        : 0

                                    radius: 9

                                    color:
                                        Pipewire.defaultAudioSink ===
                                        modelData
                                        ? root.bgLight
                                        : root.bgDark


                                    Loader {

                                        anchors.fill: parent

                                        sourceComponent:
                                            animatedHoverBorder

                                        property bool hovered:
                                            audioMouseArea.containsMouse

                                        onLoaded: {

                                            item.active =
                                                Qt.binding(
                                                    function() {
                                                        return hovered
                                                    }
                                                )
                                        }
                                    }


                                    Text {

                                        anchors {
                                            left: parent.left
                                            leftMargin: 10
                                            right: parent.right
                                            rightMargin: 10
                                            verticalCenter: parent.verticalCenter
                                        }

                                        text:
                                            modelData.description !== ""
                                            ? modelData.description
                                            : modelData.name

                                        color: root.text

                                        font.pixelSize: 10

                                        elide:
                                            Text.ElideRight
                                    }


                                    MouseArea {

                                        id: audioMouseArea

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onClicked: {

                                            if (
                                                modelData.isSink
                                            ) {

                                                Pipewire.preferredDefaultAudioSink =
                                                    modelData

                                            } else {

                                                Pipewire.preferredDefaultAudioSource =
                                                    modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }


            /*
             * ========================================================
             * DEBHYPR CONFIG
             * ========================================================
             */

            Rectangle {

                id: confMenu

                visible:
                    root.confOpen

                z: 250

                x: contextMenu.width + root.submenuGap

                y: 125

                width: 240

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

                            id: configCard

                            required property var modelData

                            width: parent.width

                            height: 34

                            radius: 7

                            color:
                                configMouse.containsMouse
                                ? root.bgDark
                                : "transparent"


                            Loader {

                                anchors.fill: parent

                                sourceComponent:
                                    animatedHoverBorder

                                property bool hovered:
                                    configMouse.containsMouse

                                onLoaded: {

                                    item.active =
                                        Qt.binding(
                                            function() {
                                                return hovered
                                            }
                                        )
                                }
                            }


                            Text {

                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                text:
                                    "Open "
                                    +
                                    modelData.label
                                    +
                                    " Config"

                                color: root.text

                                font.pixelSize: 13
                            }


                            MouseArea {

                                id: configMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked:
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
