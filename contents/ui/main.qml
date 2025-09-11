import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root
    width: 260
    height: 320

    property bool alertActive: false
    property string currentLang: "uk" // "uk" or "en"
    property int locationUID: 31 // Kyiv
    property bool tokenValid: false

    property var locationNames: {
        "31": { "uk": "м. Київ", "en": "Kyiv" }
    }

    property string statusText: {
        if (alertActive) return currentLang === "uk" ? "Тривога!" : "Air Raid!"
            else return currentLang === "uk" ? "Все ок!!" : "All ok!!"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5

        Label {
            id: statusLabel
            Layout.alignment: Qt.AlignHCenter
            text: statusText
            font.pixelSize: 22
            font.bold: true
            color: alertActive ? "red" : "#52e584"
            opacity: 1.0

            Behavior on opacity { NumberAnimation { duration: 500 } }

            Timer {
                id: blinkTimer
                interval: 500
                running: alertActive
                repeat: true
                onTriggered: statusLabel.opacity = statusLabel.opacity === 1 ? 0 : 1
            }
        }

        Label {
            id: cityLabel
            Layout.alignment: Qt.AlignHCenter
            text: locationNames[locationUID][currentLang]
            font.pixelSize: 14
            color: tokenValid ? "lightgrey" : "red"

            MouseArea {
                anchors.fill: parent
                onClicked: fetchAlertStatus()
            }
        }

        Image {
            id: alienImage
            Layout.fillWidth: true
            Layout.preferredHeight: 128
            Layout.alignment: Qt.AlignHCenter
            source: alertActive
            ? "../images/alien_alert.jpg"
            : "../images/alien_idle.jpg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Label {
            id: timeLabel
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 16
            color: "white"
            text: Qt.formatTime(new Date(), "hh:mm:ss")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeLabel.text = Qt.formatTime(new Date(), "hh:mm:ss")
            }
        }
    }

    Button {
        text: currentLang === "uk" ? "ENG" : "УКР"
        font.pixelSize: 10
        width: 30
        height: 20
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        onClicked: currentLang = currentLang === "uk" ? "en" : "uk"
    }

    // Polling timer (every 30 seconds)
    Timer {
        id: apiTimer
        interval: 30000
        running: true
        repeat: true
        onTriggered: fetchAlertStatus()
    }

    function fetchAlertStatus() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api.alerts.in.ua/v1/iot/active_air_raid_alerts/" + locationUID + ".json")
        xhr.setRequestHeader("Authorization", "Bearer YOUR TOKEN HERE")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    tokenValid = true
                    var resp = xhr.responseText.trim().replace(/"/g,"") // raw "A"/"N"/"P"
                    alertActive = (resp === "A")
                } else {
                    tokenValid = false
                    console.log("API token invalid or fetch failed: " + xhr.status)
                }
            }
        }
        xhr.send()
    }

    Component.onCompleted: {
        fetchAlertStatus() // initial fetch
    }
}
