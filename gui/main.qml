﻿// Where are we going to show the name of the pre-set we're running?
// When you press a button, when its idle (but running).
// This should also bring up the option to do an emergency stop, as well as whatever else.


import QtQuick 2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12

import Beer 1.0     // always a good idea!

// Expected QQmlContext properties:
// bool testing : whether we're windowed, for testing, or full screen
// string pathToGraph : the path to the background image

Window {
    id: window
    visible: true

    visibility: testing ? "Windowed" : "FullScreen"
    width: 640
    height: 480

    flags: testing ? Qt.Window : Qt.FramelessWindowHint

    title: qsTr("Mash-o-MatiC")

    // scale everything with screen size so it works on large screen during
    // development, and small screen on RPi.
    property int iconSize: height / 10
    property int statusIconSpacing: iconSize / 4
    property int statusFontSize: iconSize * 2/3
    property int statusFontWeight: Font.Bold

    property int buttonSize: window.width / 8

    property ListModel presets: ListModel{}

    Connections {
        target: presets
        onCountChanged: {
            console.log("presets:", presets)
            for (let i = 0; i < presets.count; i++) {
                console.log("  ",i,JSON.stringify(presets.get(i)))
            }
        }
    }

    Messages {
        id: messages
        onReceived: handle(message)
    }

    /// @todo need a mechanism to update this.
    /// Timer? Message? QFileSystemWatcher ?

    // Background image. Normally the live temperature graph.
    // Can be a splash screen at startup, etc. etc.
    Image {
        id: background
        anchors.fill: parent
        source: pathToGraph
        opacity: buttons.visible ? 0.33 : 1
    }

    // Part transparent rectangle overlaying the background image so we can
    // shade the graph depending on conditions. e.g. red if we're too hot,
    // blue too cold.
    Rectangle {
        id: shade
        anchors.fill: parent
        color: "transparent"

        property color col
        onColChanged: {
            if (col == "#00000000")
                color = "transparent"
            else
                color = Qt.rgba(col.r, col.g, col.b, 0.33)
        }
    }

    Row {
        id: rightStatus
        anchors.right: parent.right
        anchors.rightMargin: statusIconSpacing
        anchors.top: parent.top
        anchors.topMargin: statusIconSpacing
        spacing: statusIconSpacing

        Image {
            id: heater
            height: iconSize
            width: iconSize
            source: "qrc:/icons/flame.svg"
            visible: false
        }
        Item {
            id: heaterSpacer
            height: iconSize
            width: iconSize
            visible: !heater.visible
        }

        Image {
            id: pump
            height: iconSize
            width: iconSize
            source: "qrc:/icons/pump.svg"
            visible: false
            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 2000
                loops: Animation.Infinite
                running: pump.visible
            }
        }
        Item {
            id: pumpSpacer
            height: iconSize
            width: iconSize
            visible: !pump.visible
        }

        Text {
            id: time
            font.pixelSize: statusFontSize
            font.weight: statusFontWeight
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            visible: text
        }

        Image {
            id: status
            height: iconSize
            width: iconSize

            // Normally we toggle between 0 and 1, so the user sees a constantly
            // changing heart, which is a good sign.
            // If we loose comms, we switch to 2 (problem) and the user sees the
            // flashing problem icon.
            // 0 = solid heart
            // 1 = hollow heart
            // 2 = problem
            property int state: 0

            function heartbeat() {
                state = state === 0 ? 1 : 0
                setSource()
            }
            function setSource() {
                opacity = 1
                if (state === 0) {
                    source = "qrc:/icons/heart_solid.svg"
                }
                else if (state === 1) {
                    source = "qrc:/icons/heart_border.svg"
                }
                else {
                    source = "qrc:/icons/problem.svg"
                }
            }
            function problem() {
                if (state !== 2) {
                    state = 2
                    setSource()
                }
            }
            Timer {
                interval: 500
                running: status.state === 2
                repeat: true
                onTriggered: status.opacity = status.opacity ? 0 : 1
            }
            //onStateChanged: console.log("state=", state)
        }
    }

    Row {
        id: leftStatus
        anchors.left: parent.left
        anchors.leftMargin: statusIconSpacing
        anchors.top: parent.top
        anchors.topMargin: statusIconSpacing
        spacing: statusIconSpacing

        Text {
            id: temperature
            font.pixelSize: statusFontSize
            font.weight: statusFontWeight
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            text: "---"
        }
    }

    // Position 4 buttons along the bottom of the screen to line up with the
    // push buttons on the Adafruit 2315 screen.
    // Icons are set depending on the state.
    // We use RoundButton because the appearance is good, but there's no way
    // to press them without a touch screen. Presses are simulated by linking
    // to incoming messages. We emit signals in onClicked() so we can test
    // with a mouse.
    RowLayout {
        id: buttons
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.margins: buttonSize / 4
        spacing: buttonSize

        RoundButton {
            id: button1
            visible: icon.source != ""
            icon.width: buttonSize
            icon.height: buttonSize
            onClicked: menu.buttonPressed(1)
        }
        Item {
            id: button1NotVisibleSpacer
            width: buttonSize
            height: buttonSize
            visible:!button1.visible
        }

        RoundButton {
            id: button2
            visible: icon.source != ""
            icon.width: buttonSize
            icon.height: buttonSize
            onClicked: menu.buttonPressed(2)
        }
        Item {
            id: button2NotVisibleSpacer
            width: buttonSize
            height: buttonSize
            visible:!button2.visible
        }

        RoundButton {
            id: button3
            visible: icon.source != ""
            icon.width: buttonSize
            icon.height: buttonSize
            onClicked: menu.buttonPressed(3)
        }
        Item {
            id: button3NotVisibleSpacer
            width: buttonSize
            height: buttonSize
            visible:!button3.visible
        }

        RoundButton {
            id: button4
            visible: icon.source != ""
            icon.width: buttonSize
            icon.height: buttonSize
            onClicked: menu.buttonPressed(4)
        }
        Item {
            id: button4NotVisibleSpacer
            width: buttonSize
            height: buttonSize
            visible:!button4.visible
        }
    }

    Rectangle {
        id: temperatureSetter
        anchors.centerIn: parent

        property int decimals: 1
        property real value: 66.6
        property string valueString: Number(value).toLocaleString(Qt.locale(), 'f', decimals)

        function decrease() {
            value -= 1.0
        }

        function increase() {
            value += 1.0
        }

        function set() {
            messages.send("set " + valueString)
        }

        Text {
            anchors.centerIn: parent
            font.pixelSize: buttonSize
            font.bold: true
            text: parent.valueString + "°C"
        }
    }

    Item {
        id: menu
        state: "top"
        states: [
            State {
                name: "top"
                PropertyChanges { target: buttons; visible: true }
                PropertyChanges { target: button1; icon.source: "qrc:/icons/thermometer.svg" }
                PropertyChanges { target: button2; icon.source: "qrc:/icons/timeline.svg" }
                PropertyChanges { target: button3; icon.source: "" /* "qrc:/icons/timeline_add.svg" */ }
                PropertyChanges { target: button4; icon.source: "qrc:/icons/stop.svg" }
                PropertyChanges { target: temperatureSetter; visible: false }

                readonly property var actions: [menu.noAction, menu.noAction, menu.noAction, function(){ messages.send("allstop")}]
                readonly property var nextStates: ["set.temperature", "", "", ""]
            },
            State {
                name: "running"
                PropertyChanges { target: buttons; visible: false }
                PropertyChanges { target: temperatureSetter; visible: false }

                function nextStateForButtonPress(button) {
                    return "top"
                }
            },
            State {
                name: "set.temperature"
                PropertyChanges { target: buttons; visible: true }
                PropertyChanges { target: button1; icon.source: "qrc:/icons/close.svg" }
                PropertyChanges { target: button2; icon.source: "qrc:/icons/remove.svg" }
                PropertyChanges { target: button3; icon.source: "qrc:/icons/add.svg"}
                PropertyChanges { target: button4; icon.source: "qrc:/icons/check.svg" }
                PropertyChanges { target: temperatureSetter; visible: true }

                readonly property var actions: [menu.noAction, temperatureSetter.decrease, temperatureSetter.increase, temperatureSetter.set]
                readonly property var nextStates: ["top", "", "", "set.run"]
            },
            State {
                name: "set.run"
                PropertyChanges { target: buttons; visible: false }
                PropertyChanges { target: temperatureSetter; visible: false }
                function nextStateForButtonPress(button) {
                    return "set.temperature"
                }
            }
        ]

        function getCurrentStateObject() {
            for (let i = 0; i < states.length; ++i) {
                if (menu.states[i].name === menu.state) {
                    return menu.states[i]
                }
            }
            console.error("Couldn't find the current state for '"+menu.state+"'!")
            return menu.states[0]   // top
        }

        function buttonPressed(button) {
            if (button < 1 || button > 4)
                return

            let state = getCurrentStateObject()

            if (typeof state.actions !== "undefined") {
                state.actions[button - 1]()
            }

            let nextState = ""
            if (typeof state.nextStates !== "undefined") {
                // fixed state change logic can be looked up in a table
                nextState = state.nextStates[button - 1]
            }
            else {
                // complex logic is encapsulated in a function
                nextState = state.nextStateForButtonPress(button)
            }
            if (nextState !== "") {
                menu.state = nextState
            }
        }

        function noAction() {}
    }

    Timer {
        id: heartbeat
        interval: 1000
        repeat: true
        running: true

        property int missed: 0
        onTriggered: {
            if (missed > 4) {
                /// @todo Do something more serious.
                console.error("Hearbeat failed!")
                status.problem()
            }
            missed++
            messages.send("heartbeat")
        }

        function gotReply() {
            status.heartbeat()
            missed = 0
        }
    }

    function handle(message) {
        message = message.trim()
        message = message.toLowerCase()

        if (message === "hot") {
            shade.col = "red"
        }
        if (message === "cold") {
            shade.col = "blue"
        }
        if (message === "ok") {
            shade.col = "transparent"
        }
        if (message.startsWith("pump")) {
            pump.visible = parameter(message) === "on"
        }
        if (message.startsWith("heat")) {
            heater.visible = parameter(message) === "on"
        }
        if (message.startsWith("temp")) {
            var degreesC = parseFloat(parameter(message))
            temperature.text = formatTemperature(degreesC)
        }
        if (message.startsWith("time")) {
            var seconds = parseInt(parameter(message))
            time.text = formatTime(seconds)
        }
        if (message === "stop") {
            time.text = ""
        }
        if (message === "heartbeat") {
            heartbeat.gotReply()
        }
        if (message === "button 1") {
            menu.buttonPressed(1)
        }
        if (message === "button 2") {
            menu.buttonPressed(2)
        }
        if (message === "button 3") {
            menu.buttonPressed(3)
        }
        if (message === "button 4") {
            menu.buttonPressed(4)
        }
        if (message.startsWith("preset")) {
            parsePreset(message)
        }
    }

    function parameter(message) {
        return message.slice(message.lastIndexOf(" ") + 1)
    }

    function formatTemperature(degreesC) {
        var formattedTemperature = "--"
        if (!isNaN(degreesC))
            formattedTemperature = degreesC.toPrecision(3)
        return formattedTemperature + "°C"
    }

    function formatTime(seconds) {
        var formattedTime = "-- s"
        if (!isNaN(seconds)) {
            var h = Math.floor(seconds/3600)
            var m = Math.floor((seconds - h*3600)/60)
            var s = seconds % 60

            if (h) {
                formattedTime = parseInt(h) + 'h'
                if (m < 10)
                    formattedTime += '0'
                formattedTime += parseInt(m)
            }
            else if (m) {
                formattedTime = parseInt(m) + 'm'
                if (s < 10)
                    formattedTime += '0'
                formattedTime += parseInt(s)
            }
            else {
                formattedTime = parseInt(s) + 's'
            }
        }

        return formattedTime
    }

    function parsePreset(preset) {
        //console.log("parsePreset(" + preset + ")")

        let name = ""
        let description = ""

        const parts = preset.split('"')
        if (parts.length > 1) {
            name = parts[1]
        }
        if (parts.length > 3) {
            description = parts[3]
        }

        presets.append({"name":name, "description":description})
    }
}
