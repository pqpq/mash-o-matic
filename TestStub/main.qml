﻿import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.15

import Beer 1.0

ApplicationWindow {
    width: 640
    height: 480
    visible: true
    title: qsTr("Test Stub for Mash-o-matiC")

    property bool respondToHeartbeats: true
    property real temperature: 20
    property int time: 0
    property var startTime: Date.now()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        focus: true

        Text {
            Layout.fillWidth: true
            font.family: "consolas"
            text:
                "Send messages:      H - hot       P - pump      Ctrl-P - pump on\n" +
                "                    C - cold      E - heat      Ctrl-E - heat on\n" +
                "                    K - ok        -/+ - change temperature\n" +
                "                    0 - time 0    [/] - change time (</> 1 hour steps)\n" +
                "                    L - hard coded presets      I - hard coded graph\n" +
                "              1/2/3/4 - momentary key press     N - splash screen\n" +
                "                    T - test mode key presses   X - Error message\n" +
                "  B   - toggle responding to heartbeats\n" +
                "space - toggle auto scroll\n"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            Button {
                text: "1"
                onPressed: messages.send("button 1 down")
                onReleased: messages.send("button 1 up")
            }
            Button {
                text: "2"
                onPressed: messages.send("button 2 down")
                onReleased: messages.send("button 2 up")
            }
            Button {
                text: "3"
                onPressed: messages.send("button 3 down")
                onReleased: messages.send("button 3 up")
            }
            Button {
                text: "4"
                onPressed: messages.send("button 4 down")
                onReleased: messages.send("button 4 up")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "cornsilk"

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                model: ListModel {}
                delegate: Text {
                    font.family: "consolas"
                    text: value
                }

                property bool autoScrollToEnd: true
                onAutoScrollToEndChanged: {
                    if (autoScrollToEnd) {
                        positionViewAtEnd()
                    }
                }

                function add(s) {
                    if (s.endsWith('\n')) {
                        s = s.slice(0,-1)
                    }
                    const time = Date.now() - startTime
                    const seconds = time / 1000
                    model.append({value: seconds.toFixed(3) + ' ' + s})
                    if (autoScrollToEnd) {
                        positionViewAtEnd()
                    }
                }
            }
        }

        Keys.onPressed: {
            switch (event.key) {
            case Qt.Key_0:
                messages.send("time 0")
                event.accepted = true
                break
            case Qt.Key_1:
                messages.send("button 1")
                event.accepted = true
                break
            case Qt.Key_2:
                messages.send("button 2")
                event.accepted = true
                break
            case Qt.Key_3:
                messages.send("button 3")
                event.accepted = true
                break
            case Qt.Key_4:
                messages.send("button 4")
                event.accepted = true
                break
            case Qt.Key_B:
                respondToHeartbeats = !respondToHeartbeats
                if (respondToHeartbeats) {
                    list.add("Responding to heartbeats.")
                }
                else {
                    list.add("Ignoring heartbeats.")
                }
                event.accepted = true
                break
            case Qt.Key_C:
                messages.send("cold")
                event.accepted = true
                break
            case Qt.Key_E:
                messages.sendOptional("heat", event)
                event.accepted = true
                break
            case Qt.Key_H:
                messages.send("hot")
                event.accepted = true
                break
            case Qt.Key_I:
                messages.send("image ../data/graph.png")
                event.accepted = true
                break
            case Qt.Key_K:
                messages.send("ok")
                event.accepted = true
                break
            case Qt.Key_L:
                messages.send("preset \"one\" \"one\" \"blah blah <br>blah. This is really long. Will it automatically split over many lines? I wonder, yes I wonder. Oooh I wonder?\"")
                messages.send("preset \"2\" \"two\" \"blah blah blah\"")
                messages.send("preset \"3\" \"three 3\"")
                messages.send("preset \"x\" \"no closing quote")
                messages.send("preset \"no name or desription\"")
                messages.send("preset \"four.json\" \"fore\"\"no closing quote and no space separating")
                messages.send("preset blah.txt noquotes")
                messages.send("preset \"mash.json\" \"my mash\" \"55' rest\"")
                messages.send("preset \"blah\" \"blah\" \"whatever\"")
                messages.send("preset \"banana\" \"quite a long name that should elide\" \"some sort of description\"")
                messages.send("preset \"mash.txt\" \"mash.txt\" \"0934098092357\"")
                event.accepted = true
                break
            case Qt.Key_N:
                messages.send("image ../data/splash.png")
                event.accepted = true
                break
            case Qt.Key_P:
                messages.sendOptional("pump", event)
                event.accepted = true
                break
            case Qt.Key_T:
                messages.send("button 4 down")
                messages.send("button 1 down")
                messages.send("button 1 up")
                messages.send("button 4 up")
                messages.send("testshow \"SkjdshfkH    44.3<br>"+
                                         "abc12345     10.1<br>" +
                                         "0340j0f09j3409fjj34 12.3<br>" +
                                         "0430if-0ie-0Fi0R 33.003\"")
                event.accepted = true
                break;
            case Qt.Key_X:
                messages.send("error \"What are you doing Dave?\"")
                event.accepted = true
                break;
            case Qt.Key_Minus:
                temperature -= 0.1
                messages.send("temp " + temperature)
                event.accepted = true
                break
            case Qt.Key_Plus:
            case Qt.Key_Equal:
                temperature += 0.1
                messages.send("temp " + temperature)
                event.accepted = true
                break
            case Qt.Key_BracketLeft:
                time -= 1
                messages.send("time " + time)
                event.accepted = true
                break
            case Qt.Key_BracketRight:
                time += 1
                messages.send("time " + time)
                event.accepted = true
                break
            case Qt.Key_Less:
            case Qt.Key_Comma:
                time -= 3600
                messages.send("time " + time)
                event.accepted = true
                break
            case Qt.Key_Greater:
            case Qt.Key_Period:
                time += 3600
                messages.send("time " + time)
                event.accepted = true
                break
            case Qt.Key_Space:
                list.autoScrollToEnd = !list.autoScrollToEnd
                event.accepted = true
                break
            }
        }
    }

    Messages {
        id: messages
        onReceived: handle(message)
        onSent: list.add("Tx: " + message)
        onEof: {
            list.add("Rx: EOF")
        }

        function sendOptional(message, event) {
            if (event.modifiers & Qt.ControlModifier) {
                message += " on"
            }
            send(message)
        }
    }

    function handle(message) {
        list.add("Rx: " + message)
        if (message.trim() === "heartbeat" && respondToHeartbeats) {
            messages.send(message)
        }
    }
}
