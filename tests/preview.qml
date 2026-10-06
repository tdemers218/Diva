import Quickshell
import QtQuick
import QtQuick.Window
import "plugin" as Diva
ShellRoot {
  Component.onCompleted: {
    for (var i=0;i<6;i++) {
      var file = ["Desktop.qml","Diva.qml","Companion.qml","BarWidget.qml","ControlPage.qml","Service.qml"][i]
      var c = Qt.createComponent(Qt.resolvedUrl("plugin/" + file))
      if (c.status !== Component.Ready) {
        if (c.errorString().indexOf("No PanelWindow backend loaded") >= 0)
          console.log("Live layer-shell check unavailable offscreen: " + file)
        else throw new Error(c.errorString())
      }
    }
  }
  Window {
    id: window
    visible: true; width: 1100; height: 760; color: "#20121e"
    QtObject {
      id: mock
      property color ink: "#f6e9ef"
      property color rose: "#eaa3c0"
      property color soft: "#cfb2c2"
      property color tileColor: Qt.rgba(1,1,1,0.075)
      property color tileSelected: Qt.rgba(0.92,0.64,0.75,0.2)
      property color hairline: Qt.rgba(1,1,1,0.13)
      property color field: Qt.rgba(0,0,0,0.26)
      property color deepRose: "#b8738f"
      property string fontFamily: "Adwaita Sans"
      property string iconFamily: "JetBrainsMono Nerd Font"
      property string pluginDir: decodeURIComponent(String(Qt.resolvedUrl("plugin")).replace(/^file:\/\//,""))
      property var state: ({volume:40,muted:false,brightness:70})
      property string page: "home"
      function ms(v) { return 0 }
      function control(op,v) {}
      function runQuiet(argv,s) {}
      function goHome() {}
    }
    Rectangle { id: controlFrame; x: 20; y: 20; width: controls.width + 48; height: controls.height + 48; radius: 28; color: "#2b1c29"; border.color: "#614252" }
    Diva.ControlPage { parent: controlFrame; id: controls; x: 24; y: 24; width: 600; height: 430; diva: mock; section: "audio" }
    Diva.Dock { id: dock; x: 20; y: 690; barSize: 48 }
    Diva.OverviewView { id: overview; anchors.fill: parent; visible: false; monitorName: "test"; windows: [{address:"0x1234",title:"Firefox",workspace:1,icon:"firefox",at:[20,20],size:[1000,700],monitor:"test",handle:null},{address:"0x1235",title:"Fichiers",workspace:1,icon:"org.gnome.Nautilus",at:[1100,20],size:[1000,700],monitor:"test",handle:null}]; workspaces: [{id:1,name:"Espace 1"},{id:2,name:"Espace 2"}] }

    Timer {
      id: captures
      property int step: 0
      interval: 450; running: true; repeat: true
      onTriggered: {
        if (step === 0) {
          controls.section = "network"
          controls.wifiEnabled = true
          controls.wifiDevice = ({scannerEnabled:false,networks:{values:[]}})
          controls.networks = [{name:"Maison",connected:true,known:true,signalStrength:0.92,security:1},{name:"Studio",connected:false,known:true,signalStrength:0.78,security:1},{name:"Café du coin",connected:false,known:false,signalStrength:0.61,security:1}]
        } else if (step === 1) controlFrame.grabToImage(function(r) { r.saveToFile("/tmp/diva-wifi.png") })
        else if (step === 2) {
          controls.section = "bluetooth"
          controls.adapter = ({enabled:true,discovering:false})
          controls.devices = [{name:"Écouteurs de Julie",address:"AA:BB:CC:DD:EE:01",paired:true,connected:true},{name:"Souris",address:"AA:BB:CC:DD:EE:02",paired:true,connected:false},{name:"Haut-parleur",address:"AA:BB:CC:DD:EE:03",paired:false,connected:false}]
        } else if (step === 3) controlFrame.grabToImage(function(r) { r.saveToFile("/tmp/diva-bluetooth.png") })
        else if (step === 4) {
          controls.section = "audio"
          controls.audioNodes = [{id:1,name:"speakers",description:"Haut-parleurs intégrés",isSink:true},{id:2,name:"headphones",description:"Écouteurs",isSink:true}]
          controls.sink = controls.audioNodes[0]
        }
        else if (step === 5) controlFrame.grabToImage(function(r) { r.saveToFile("/tmp/diva-controls.png") })
        else if (step === 6) controls.section = "appearance"
        else if (step === 7) controlFrame.grabToImage(function(r) { r.saveToFile("/tmp/diva-appearance.png") })
        else if (step === 8) {
          controls.section = "network"
          controls.passwordNetwork = controls.networks[2]
          controls.contentY = Math.max(0, controls.contentHeight - controls.height)
        }
        else if (step === 9) controlFrame.grabToImage(function(r) { r.saveToFile("/tmp/diva-password.png") })
        else if (step === 10) { controls.visible = false; controlFrame.visible = false; overview.visible = true }
        else if (step === 11) overview.grabToImage(function(r) { r.saveToFile("/tmp/diva-overview.png") })
        else if (step === 12) { overview.visible = false; controlFrame.visible = true; controls.visible = true; controls.section = "bluetooth"; controls.width = 900; controls.height = 680 }
        else if (step === 13) controlFrame.grabToImage(function(r) { r.saveToFile("/tmp/diva-controls-wide.png") })
        else if (step === 14) controls.width = 350
        else if (step === 15) controlFrame.grabToImage(function(r) { r.saveToFile("/tmp/diva-controls-narrow.png") })
        else if (step === 16) Qt.quit()
        step++
      }
    }
  }
}
