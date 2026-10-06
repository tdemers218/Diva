import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs.Commons

// Native settings, inside Diva. Shared desktop services supply live state;
// credentials go directly to NetworkManager, never into argv or Diva's files.
Flickable {
  id: root
  property var diva
  property string section: "network"
  property string status: ""
  property var pendingNetwork: null
  property string networkOperation: ""
  property var passwordNetwork: null
  property string forgetName: ""
  property var walls: []
  property var audioNodes: []
  property var audioStreams: []
  property var scannerDevice: null
  property bool scannerOwned: false
  property string pendingBluetooth: ""
  property string bluetoothOperation: ""
  property int bluetoothWaits: 0
  property bool discoveryOwned: false
  property bool wifiEnabled: Networking.wifiEnabled
  property var adapter: Bluetooth.defaultAdapter
  property var wifiDevice: {
    var ds = Networking.devices.values || []
    return ds.find(function(d) { return d.type === DeviceType.Wifi }) || null
  }
  property var networks: (wifiDevice ? wifiDevice.networks.values.slice() : []).sort(function(a,b) {
    if (a.connected !== b.connected) return a.connected ? -1 : 1
    if (a.known !== b.known) return a.known ? -1 : 1
    return b.signalStrength - a.signalStrength
  })
  property var devices: Bluetooth.devices.values || []
  property var sink: Pipewire.defaultAudioSink
  property var source: Pipewire.defaultAudioSource
  contentHeight: body.height
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  Controls.ScrollBar.vertical: Controls.ScrollBar {
    policy: Controls.ScrollBar.AsNeeded
    width: Style.space(3)
    contentItem: Rectangle { implicitWidth: Style.space(3); radius: width / 2; color: root.diva.rose; opacity: 0.45 }
    background: Item {}
  }

  function updateAudio() {
    var nodes = Pipewire.nodes.values || []
    audioNodes = nodes.filter(function(n) { return n && !n.isStream })
    audioStreams = nodes.filter(function(n) { return n && n.isStream && n.isSink })
  }
  function connectNetwork(net, secret) {
    if (pendingNetwork) return
    status = "Connexion en cours…"
    pendingNetwork = net
    networkOperation = "connect"
    timeout.restart()
    if (secret) net.connectWithPsk(secret)
    else net.connect()
    password.clear()
  }
  function networkAction(net, operation) {
    if (pendingNetwork) return
    pendingNetwork = net
    networkOperation = operation
    status = operation === "forget" ? "J'oublie ce réseau…" : "Déconnexion…"
    timeout.restart()
    if (operation === "forget") net.forget()
    else net.disconnect()
  }
  function chooseNetwork(net) {
    if (pendingNetwork) return
    forgetName = ""
    if (net.connected) { networkAction(net, "disconnect"); return }
    if (net.known || net.security === WifiSecurityType.Open || net.security === WifiSecurityType.Owe) { connectNetwork(net, ""); return }
    if (net.security === WifiSecurityType.Wpa2Eap || net.security === WifiSecurityType.WpaEap || net.security === WifiSecurityType.Leap || net.security === WifiSecurityType.DynamicWep) {
      status = "Ce réseau demande un profil d'entreprise. Un profil déjà enregistré peut être utilisé ici."
      return
    }
    passwordNetwork = net
    password.clear()
    Qt.callLater(function() { password.focusField(); root.contentY = Math.max(0, Math.min(passwordCard.mapToItem(body, 0, 0).y, root.contentHeight - root.height)) })
  }
  function bluetoothAction(device, operation) {
    if (btAction.running || pendingBluetooth) return
    pendingBluetooth = device.address
    bluetoothOperation = operation
    status = operation === "disconnect" ? "Déconnexion…" : operation === "forget" ? "J'oublie cet appareil…" : "Connexion à " + (device.name || device.address) + "…"
    btAction.command = ["omarchy-bluetooth-device", operation, device.address]
    bluetoothWaits = 0
    btAction.running = true
  }
  function scan() {
    stopScan()
    scannerDevice = wifiDevice
    if (scannerDevice && !scannerDevice.scannerEnabled) { scannerDevice.scannerEnabled = true; scannerOwned = true }
    scanTimer.restart()
  }
  function stopScan() {
    if (scannerOwned && scannerDevice) scannerDevice.scannerEnabled = false
    scannerOwned = false; scannerDevice = null
  }
  function discover() {
    if (!adapter || !adapter.enabled) return
    if (!adapter.discovering) { adapter.discovering = true; discoveryOwned = true }
    discoveryTimeout.restart()
  }
  function stopDiscovery() {
    if (discoveryOwned && adapter) adapter.discovering = false
    discoveryOwned = false
  }
  onSectionChanged: { contentY = 0; status = ""; forgetName = ""; password.clear(); passwordNetwork = null; stopDiscovery(); stopScan() }
  Component.onCompleted: updateAudio()
  Component.onDestruction: { stopDiscovery(); stopScan(); password.clear() }
  PwObjectTracker { objects: root.audioNodes.concat(root.audioStreams) }
  Timer { interval: 1000; running: root.visible && root.section === "audio"; repeat: true; onTriggered: root.updateAudio() }
  Timer { id: discoveryTimeout; interval: 20000; onTriggered: root.stopDiscovery() }
  Timer {
    id: timeout; interval: 30000
    onTriggered: { root.status = root.networkOperation === "connect" ? "La connexion n'a pas abouti. Vérifie le réseau et réessaie." : "Le réseau n'a pas répondu. Réessaie."; root.pendingNetwork = null; root.networkOperation = "" }
  }
  Connections {
    target: root.pendingNetwork
    function onConnectionFailed(reason) {
      root.status = "La connexion a échoué. Vérifie le réseau et tes identifiants."
      root.passwordNetwork = root.networkOperation === "connect" ? root.pendingNetwork : null
      root.pendingNetwork = null
      root.networkOperation = ""
      timeout.stop()
    }
    function onConnectedChanged() { root.checkNetwork() }
    function onKnownChanged() { root.checkNetwork() }
    function onStateChangingChanged() { root.checkNetwork() }
  }
  function checkNetwork() {
    var n = pendingNetwork
    if (!n) return
    var done = networkOperation === "connect" ? n.connected : networkOperation === "forget" ? !n.known : !n.connected && !n.stateChanging
    if (!done) return
    status = networkOperation === "connect" ? "Connectée à " + n.name : networkOperation === "forget" ? "Réseau oublié." : "Déconnectée."
    passwordNetwork = null; pendingNetwork = null; networkOperation = ""; timeout.stop()
  }
  function checkBluetooth() {
    var d = root.devices.find(function(v) { return v.address === root.pendingBluetooth })
    var ok = root.bluetoothOperation === "forget" ? !d || !d.paired
           : root.bluetoothOperation === "disconnect" ? !d || !d.connected : d && d.connected
    if (ok) { root.status = "C'est fait."; root.pendingBluetooth = ""; bluetoothSettled.stop(); return }
    if (++root.bluetoothWaits >= 10) {
      root.status = "L'appareil n'a pas répondu. Mets-le en mode jumelage et réessaie."
      root.pendingBluetooth = ""; bluetoothSettled.stop()
    }
  }
  Process {
    id: btAction
    // BlueZ updates may arrive after the command returns.
    onExited: { root.checkBluetooth(); if (root.pendingBluetooth) bluetoothSettled.restart() }
  }
  Timer { id: bluetoothSettled; interval: 500; repeat: true; onTriggered: root.checkBluetooth() }
  Process {
    id: wallpaperList
    command: [root.diva ? root.diva.pluginDir + "/bin/diva-wallpapers" : "", "list"]
    running: root.section === "appearance" && !!root.diva
    stdout: StdioCollector { onStreamFinished: { try { root.walls = JSON.parse(text) } catch (e) { root.status = "Impossible de lire les fonds d'écran." } } }
  }
  Process {
    id: wallpaperApply
    onExited: function(code) { root.status = code === 0 ? "Fond d'écran changé." : "Impossible de changer le fond d'écran." }
  }


  readonly property bool wide: width >= Style.space(540)
  readonly property real sideWidth: Style.space(190)
  readonly property real mainWidth: wide ? width - sideWidth - Style.space(16) : width

  component Label: Text {
    textFormat: Text.PlainText
    color: root.diva.ink
    font.family: root.diva.fontFamily
    font.pixelSize: Style.space(13)
    wrapMode: Text.WordWrap
  }
  component Heading: Label {
    font.pixelSize: Style.space(11)
    font.weight: Font.Medium
    color: root.diva.soft
    height: Style.space(24)
    verticalAlignment: Text.AlignVCenter
  }
  component Panel: Rectangle {
    default property alias contents: inside.data
    width: parent.width
    implicitHeight: inside.height + Style.space(28)
    radius: Style.space(18)
    color: root.diva.tileColor
    border.color: root.diva.hairline
    Column { id: inside; x: Style.space(14); y: Style.space(14); width: parent.width - Style.space(28); spacing: Style.space(8) }
  }
  component Divider: Rectangle { width: parent.width; height: 1; color: root.diva.hairline; opacity: 0.55 }
  component Empty: Item {
    property string title: ""
    property string caption: ""
    width: parent.width; implicitHeight: emptyText.height + Style.space(24)
    Column {
      id: emptyText; x: Style.space(8); y: Style.space(12); width: parent.width - Style.space(16); spacing: Style.space(6)
      Label { width: parent.width; text: parent.parent.title; font.weight: Font.Medium }
      Label { width: parent.width; text: parent.parent.caption; font.pixelSize: Style.space(11); color: root.diva.soft }
    }
  }
  Column {
    id: body
    width: root.width
    spacing: Style.space(16)
    Flow {
      width: parent.width; spacing: Style.space(4)
      Repeater {
        model: [{id:"network",name:"Wi-Fi",icon:"wifi"},{id:"bluetooth",name:"Bluetooth",icon:"bluetooth"},{id:"audio",name:"Son",icon:"volume-high"},{id:"appearance",name:"Ambiance",icon:"palette"}]
        Rectangle {
          required property var modelData
          width: navLabel.implicitWidth + Style.space(28); height: Style.space(34); radius: Style.space(10)
          color: root.section === modelData.id ? root.diva.tileSelected : navMouse.containsMouse ? root.diva.tileColor : "transparent"
          Text { id: navLabel; anchors.centerIn: parent; text: modelData.name; color: root.section === modelData.id ? root.diva.ink : root.diva.soft; font.family: root.diva.fontFamily; font.pixelSize: Style.space(12); font.weight: root.section === modelData.id ? Font.DemiBold : Font.Normal }
          activeFocusOnTab: true
          Keys.onReturnPressed: root.diva.page = modelData.id
          Keys.onSpacePressed: root.diva.page = modelData.id
          MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.diva.page = modelData.id }
          Rectangle { anchors.fill: parent; radius: parent.radius; color: "transparent"; border.color: root.diva.rose; visible: parent.activeFocus }
        }
      }
    }
    Label { width: parent.width; visible: root.status !== ""; text: root.status; color: root.diva.rose; font.pixelSize: Style.space(11) }

    Flow {
      visible: root.section === "network"; width: parent.width; spacing: Style.space(16)
      Column {
        width: root.wide ? root.sideWidth : parent.width; spacing: Style.space(12)
        Panel {
          DivaSwitch { width: parent.width; diva: root.diva; label: "Wi-Fi"; caption: root.wifiEnabled ? "Activé" : "Désactivé"; checked: root.wifiEnabled; enabled: !!root.wifiDevice && !root.pendingNetwork; onToggled: function(v) { Networking.wifiEnabled = v } }
        }
        Label { width: parent.width; text: root.wifiEnabled ? "Choisis un réseau pour te connecter." : "Active le Wi-Fi pour afficher les réseaux."; color: root.diva.soft; font.pixelSize: Style.space(11); visible: root.wide }
      }
      Column {
        width: root.mainWidth; spacing: Style.space(12)
        Panel {
          Row {
            width: parent.width
            Label { width: parent.width - search.width; height: search.height; verticalAlignment: Text.AlignVCenter; text: "Réseaux"; font.weight: Font.DemiBold }
            DivaButton { id: search; diva: root.diva; glyph: "restart"; width: Style.space(30); height: width; color: "transparent"; border.color: "transparent"; enabled: !!root.wifiDevice && root.wifiEnabled && !root.scannerOwned; onClicked: root.scan() }
          }
          Divider {}
          Timer { id: scanTimer; interval: 10000; onTriggered: root.stopScan() }
          Repeater {
            model: root.section === "network" && root.wifiEnabled ? root.networks : []
            ControlDeviceRow {
              required property var modelData
              diva: root.diva; title: modelData.name || "Réseau masqué"
              subtitle: (modelData.connected ? "Connecté" : modelData.known ? "Enregistré" : modelData.security === WifiSecurityType.Open ? "Ouvert" : "Sécurisé") + " · " + Math.round(modelData.signalStrength * 100) + " %"
              forgetLabel: "Oublier ce réseau"
              selected: modelData.connected; busy: root.pendingNetwork === modelData; enabled: !root.pendingNetwork; canForget: modelData.known
              action: modelData.connected ? "Quitter" : "Connecter"
              onActivated: root.chooseNetwork(modelData)
              onForgotten: root.networkAction(modelData, "forget")
            }
          }
          Empty { visible: !root.wifiDevice || !root.wifiEnabled || root.networks.length === 0; title: !root.wifiDevice ? "Aucun adaptateur Wi-Fi" : !root.wifiEnabled ? "Wi-Fi désactivé" : root.scannerOwned ? "Recherche en cours…" : "Aucun réseau trouvé"; caption: "Les réseaux disponibles apparaîtront ici." }
        }
        Panel {
          id: passwordCard; visible: !!root.passwordNetwork
          Label { width: parent.width; text: root.passwordNetwork ? root.passwordNetwork.name : ""; font.weight: Font.DemiBold }
          DivaInput { id: password; width: parent.width; diva: root.diva; password: true; placeholder: "Mot de passe du réseau"; onCommitted: function(t) { if (root.passwordNetwork && t) root.connectNetwork(root.passwordNetwork, t) } }
          Flow {
            width: parent.width; spacing: Style.space(8)
            DivaButton { diva: root.diva; text: "Connecter"; primary: true; enabled: !!password.text && !root.pendingNetwork; onClicked: root.connectNetwork(root.passwordNetwork, password.text) }
            DivaButton { diva: root.diva; text: "Annuler"; onClicked: { root.passwordNetwork = null; password.clear() } }
          }
        }
      }
    }

    Flow {
      visible: root.section === "bluetooth"; width: parent.width; spacing: Style.space(16)
      Column {
        width: root.wide ? root.sideWidth : parent.width; spacing: Style.space(12)
        Panel {
          DivaSwitch { width: parent.width; diva: root.diva; label: "Bluetooth"; caption: root.adapter && root.adapter.enabled ? "Activé" : "Désactivé"; checked: !!root.adapter && root.adapter.enabled; enabled: !!root.adapter; onToggled: function(v) { root.diva.runQuiet(["omarchy-bluetooth-power", v ? "on" : "off"], "Bluetooth changé.") } }
        }
        Label { width: parent.width; text: "Pour un nouvel appareil, active son mode jumelage."; color: root.diva.soft; font.pixelSize: Style.space(11) }
        DivaButton { diva: root.diva; text: root.adapter && root.adapter.discovering ? "Recherche…" : "Rechercher"; glyph: "magnify"; enabled: !!root.adapter && root.adapter.enabled && !root.adapter.discovering; onClicked: root.discover() }
      }
      Panel {
        width: root.mainWidth
        Label { text: "Appareils"; font.weight: Font.DemiBold }
        Divider {}
        Repeater {
          model: [{title:"Mes appareils",paired:true},{title:"À proximité",paired:false}]
          Column {
            required property var modelData
            width: parent.width; spacing: Style.space(4)
            visible: !!root.adapter && root.adapter.enabled
            Heading { width: parent.width; text: modelData.title }
            Repeater {
              model: root.section === "bluetooth" ? root.devices.filter(function(d) { return !!d.paired === modelData.paired }).sort(function(a,b) { return Number(b.connected) - Number(a.connected) }) : []
              ControlDeviceRow {
                required property var modelData
                diva: root.diva; glyph: "bluetooth"; title: modelData.name || modelData.address
                subtitle: modelData.connected ? "Connecté" : modelData.paired ? "Enregistré" : "Disponible"
                selected: modelData.connected; busy: root.pendingBluetooth === modelData.address; enabled: !root.pendingBluetooth; canForget: modelData.paired
                action: modelData.connected ? "Quitter" : modelData.paired ? "Connecter" : "Jumeler"
                onActivated: root.bluetoothAction(modelData, modelData.connected ? "disconnect" : modelData.paired ? "connect" : "pair")
                onForgotten: root.bluetoothAction(modelData, "forget")
              }
            }
          }
        }
        Empty { visible: !root.adapter || !root.adapter.enabled || root.devices.length === 0; title: !root.adapter ? "Aucun adaptateur Bluetooth" : !root.adapter.enabled ? "Bluetooth désactivé" : "Aucun appareil trouvé"; caption: "Lance une recherche pour retrouver tes appareils." }
      }
    }

    Flow {
      visible: root.section === "audio"; width: parent.width; spacing: Style.space(16)
      Panel {
        width: root.wide ? Math.max(root.mainWidth, Style.space(300)) : parent.width
        Label { text: "Sortie audio"; font.weight: Font.DemiBold }
        DivaSlider { width: parent.width; height: Style.space(44); radius: Style.space(14); diva: root.diva; label: "Volume"; glyph: "volume-high"; value: root.diva.state.volume; onMoved: function(v) { root.diva.control("volume", v) } }
        DivaSwitch { width: parent.width; diva: root.diva; label: "Couper le son"; checked: root.diva.state.muted; onToggled: root.diva.control("mute", "") }
        Divider {}
        Repeater {
          model: root.section === "audio" ? root.audioNodes.filter(function(n) { return n.isSink }) : []
          ControlDeviceRow {
            required property var modelData
            diva: root.diva; glyph: "headphones"; title: modelData.description || modelData.name
            selected: !!root.sink && root.sink.id === modelData.id; subtitle: selected ? "Sortie actuelle" : "Disponible"; action: selected ? "Active" : "Choisir"; enabled: !selected
            onActivated: { Pipewire.preferredDefaultAudioSink = modelData; Quickshell.execDetached(["omarchy-audio-output-set-default", String(modelData.id), modelData.name]) }
          }
        }
        Empty { visible: !root.sink; title: "Aucune sortie audio"; caption: "Connecte des écouteurs ou un haut-parleur." }
      }
      Panel {
        width: root.wide ? root.sideWidth : parent.width
        Label { text: "Microphone"; font.weight: Font.DemiBold }
        DivaSlider { width: parent.width; height: Style.space(44); radius: Style.space(14); diva: root.diva; label: ""; glyph: "music"; value: root.source && root.source.audio ? Math.round(root.source.audio.volume * 100) : -1; onMoved: function(v) { if (root.source && root.source.audio) root.source.audio.volume = v / 100 } }
        DivaSwitch { width: parent.width; diva: root.diva; label: "Muet"; checked: root.source && root.source.audio ? root.source.audio.muted : false; enabled: !!root.source && !!root.source.audio; onToggled: function(v) { if (root.source && root.source.audio) root.source.audio.muted = v } }
        Repeater {
          model: root.section === "audio" ? root.audioNodes.filter(function(n) { return !n.isSink && n.audio && String(n.name).indexOf("monitor") < 0 }) : []
          Column {
            required property var modelData
            width: parent.width; spacing: Style.space(6)
            Label { width: parent.width; text: modelData.description || modelData.name; color: root.source === modelData ? root.diva.rose : root.diva.soft; font.pixelSize: Style.space(11) }
            DivaButton { diva: root.diva; text: root.source === modelData ? "Actif" : "Choisir"; enabled: root.source !== modelData; onClicked: { Pipewire.preferredDefaultAudioSource = modelData; Quickshell.execDetached(["omarchy-audio-input-set-default", String(modelData.id), modelData.name]) } }
          }
        }
      }
      Panel {
        visible: root.audioStreams.length > 0
        Label { text: "Applications"; font.weight: Font.DemiBold }
        Repeater {
          model: root.section === "audio" ? root.audioStreams : []
          Column {
            required property var modelData
            width: parent.width; spacing: Style.space(8)
            DivaSlider { width: parent.width; height: Style.space(44); radius: Style.space(14); diva: root.diva; label: modelData.description || modelData.name; glyph: "music"; value: modelData.audio ? Math.round(modelData.audio.volume * 100) : -1; onMoved: function(v) { if (modelData.audio) modelData.audio.volume = v / 100 } }
            DivaSwitch { width: parent.width; diva: root.diva; label: "Couper le son"; checked: modelData.audio ? modelData.audio.muted : false; onToggled: function(v) { if (modelData.audio) modelData.audio.muted = v } }
          }
        }
      }
    }

    Flow {
      visible: root.section === "appearance"; width: parent.width; spacing: Style.space(16)
      Panel {
        width: root.mainWidth
        Label { text: "Écran"; font.weight: Font.DemiBold }
        DivaSlider { width: parent.width; height: Style.space(44); radius: Style.space(14); diva: root.diva; label: "Luminosité"; glyph: "sun"; value: root.diva.state.brightness; onMoved: function(v) { root.diva.control("brightness", Math.max(1,v)) } }
        DivaSwitch { width: parent.width; diva: root.diva; label: "Lumière de nuit"; caption: "Des couleurs plus chaudes le soir."; checked: root.diva.state.nightlight === true; onToggled: root.diva.runQuiet(["omarchy-toggle-nightlight"], "Lumière de nuit changée.") }
      }
      Panel {
        width: root.wide ? root.sideWidth : parent.width
        DivaGlyph { name: "palette"; family: root.diva.iconFamily; size: Style.space(24); color: root.diva.rose }
        Label { text: "Style de Diva"; font.weight: Font.DemiBold }
        Label { width: parent.width; text: "Couleurs et animations"; color: root.diva.soft; font.pixelSize: Style.space(11) }
        DivaButton { diva: root.diva; text: "Personnaliser"; onClicked: root.diva.page = "settings" }
      }
      Column {
        width: parent.width; spacing: Style.space(10)
        Label { text: "Fonds d’écran"; font.weight: Font.DemiBold }
        Flow {
          width: parent.width; spacing: Style.space(10)
          Repeater {
            model: root.walls
            Rectangle {
              required property var modelData
              width: (parent.width - (Math.max(1, Math.floor((parent.width + Style.space(10)) / Style.space(160))) - 1) * Style.space(10)) / Math.max(1, Math.floor((parent.width + Style.space(10)) / Style.space(160)))
              height: width * 0.625; radius: Style.space(12); clip: true; color: root.diva.tileColor
              Image { anchors.fill: parent; source: "file://" + encodeURI(modelData.path).replace(/#/g,"%23").replace(/\?/g,"%3F"); fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 360 }
              Rectangle { anchors.fill: parent; color: "transparent"; border.width: wallpaperMouse.containsMouse ? 2 : 1; border.color: wallpaperMouse.containsMouse ? root.diva.rose : root.diva.hairline; radius: parent.radius }
              MouseArea { id: wallpaperMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !wallpaperApply.running; onClicked: { wallpaperApply.command = [root.diva.pluginDir + "/bin/diva-wallpapers", "set", modelData.path]; wallpaperApply.running = true } }
            }
          }
        }
        Empty { visible: root.walls.length === 0; title: "Aucun fond d’écran"; caption: "Les fonds du thème actuel apparaîtront ici." }
      }
    }
    Item { width: 1; height: Style.space(8) }
  }
}
