import QtQuick
import qs.Commons
import "core/Actions.js" as Actions
import "core/Icons.js" as Icons

// What the menu shows before she types: her favourite places as app icons,
// then a control centre in the iOS manner: connections and sound as round
// switches, volume and brightness as sliders, and the power buttons.
Column {
  id: root
  property var diva
  spacing: Style.space(14)

  // A round switch with its name underneath; `more` opens the full panel.
  component Switch: Item {
    id: sw
    property string glyph: ""
    property string label: ""
    property string caption: ""
    property bool on: false
    property bool hasMore: false
    signal toggled()
    signal more()
    width: Style.space(104)
    height: Style.space(74)

    Rectangle {
      id: knob
      anchors.horizontalCenter: parent.horizontalCenter
      width: Style.space(46)
      height: width
      radius: width / 2
      color: sw.on ? root.diva.rose : root.diva.tileColor
      border.width: 1
      border.color: sw.on ? "transparent" : root.diva.hairline
      scale: press.pressed ? 0.92 : 1
      Behavior on color { ColorAnimation { duration: root.diva.ms(160) } }
      Behavior on scale { NumberAnimation { duration: root.diva.ms(90) } }
      Text {
        anchors.centerIn: parent
        text: Icons.glyph(sw.glyph)
        color: sw.on ? "#3a1f2e" : root.diva.ink
        font.family: root.diva.iconFamily
        font.pixelSize: Style.space(22)
      }
      MouseArea { id: press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.toggled() }
    }
    Column {
      anchors.top: knob.bottom
      anchors.topMargin: Style.space(4)
      width: parent.width
      Text {
        textFormat: Text.PlainText
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: sw.label + (sw.hasMore ? "  ›" : "")
        color: root.diva.ink
        font.family: root.diva.fontFamily
        font.pixelSize: Style.space(12)
        font.weight: Font.Medium
        elide: Text.ElideRight
        MouseArea { anchors.fill: parent; enabled: sw.hasMore; cursorShape: Qt.PointingHandCursor; onClicked: sw.more() }
      }
      Text {
        textFormat: Text.PlainText
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: sw.caption
        color: root.diva.soft
        font.family: root.diva.fontFamily
        font.pixelSize: Style.space(10)
        elide: Text.ElideRight
      }
    }
  }

  // Favourites, as app icons.
  Row {
    width: parent.width
    Repeater {
      model: root.diva.tiles
      Item {
        id: fav
        required property int index
        required property var modelData
        readonly property bool current: index === root.diva.selected
        property real pop: 0
        width: root.width / Math.max(1, root.diva.tiles.length)
        height: Style.space(96)

        SequentialAnimation {
          running: true
          PauseAnimation { duration: root.diva.stagger ? fav.index * root.diva.ms(28) : 0 }
          NumberAnimation { target: fav; property: "pop"; from: 0; to: 1; duration: root.diva.ms(260); easing.type: Easing.OutBack }
        }

        Rectangle {
          id: icon
          anchors.horizontalCenter: parent.horizontalCenter
          y: Style.space(4)
          width: Style.space(60)
          height: width
          radius: Style.space(19)
          opacity: fav.pop
          scale: (0.8 + 0.2 * fav.pop) * (tap.pressed ? 0.93 : fav.current ? 1.08 : 1)
          border.width: fav.current ? Style.space(1.5) : 1
          border.color: fav.current ? root.diva.rose : Qt.rgba(1, 1, 1, 0.22)
          gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0.96, 0.72, 0.82, 0.42) }
            GradientStop { position: 1; color: Qt.rgba(0.72, 0.42, 0.56, 0.42) }
          }
          Behavior on scale { NumberAnimation { duration: root.diva.ms(130); easing.type: Easing.OutCubic } }
          Text {
            anchors.centerIn: parent
            text: fav.modelData.glyph ? Icons.glyph(fav.modelData.glyph) : ""
            color: root.diva.ink
            font.family: root.diva.iconFamily
            font.pixelSize: Style.space(29)
          }
        }
        Text {
          textFormat: Text.PlainText
          anchors.top: icon.bottom
          anchors.topMargin: Style.space(7)
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: fav.modelData.title
          color: root.diva.ink
          opacity: fav.pop
          font.family: root.diva.fontFamily
          font.pixelSize: Style.space(12)
          font.weight: Font.Medium
          elide: Text.ElideRight
        }
        MouseArea {
          id: tap
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onContainsMouseChanged: if (containsMouse && root.diva.selected !== fav.index) {
            root.diva.selected = fav.index
            root.diva.cancelConfirm()
          }
          onClicked: root.diva.activate(fav.index)
        }
      }
    }
  }

  // Control centre.
  Row {
    width: parent.width
    spacing: Style.space(12)

    Rectangle {
      id: switches
      width: Style.space(240)
      height: Style.space(178)
      radius: Style.space(26)
      color: root.diva.tileColor
      border.width: 1
      border.color: root.diva.hairline

      Grid {
        anchors.centerIn: parent
        columns: 2
        columnSpacing: Style.space(8)
        rowSpacing: Style.space(8)
        Switch {
          glyph: "wifi"; label: "Wi-Fi"; hasMore: true
          on: root.diva.state.wifi === true
          caption: root.diva.state.wifi ? (root.diva.state.network || "Pas connecté") : "Éteint"
          onToggled: root.diva.control("wifi", "")
          onMore: root.diva.runAndClose(["omarchy-shell", "shell", "toggle", "omarchy.network"])
        }
        Switch {
          glyph: "bluetooth"; label: "Bluetooth"; hasMore: true
          on: root.diva.state.bluetooth === true
          caption: root.diva.state.bluetooth ? "Allumé" : "Éteint"
          onToggled: root.diva.control("bluetooth", "")
          onMore: root.diva.runAndClose(["omarchy-shell", "shell", "toggle", "omarchy.bluetooth"])
        }
        Switch {
          glyph: "volume-off"; label: "Silence"
          on: root.diva.state.muted === true
          caption: root.diva.state.muted ? "Son coupé" : "Son actif"
          onToggled: root.diva.control("mute", "")
        }
        Switch {
          glyph: "moon"; label: "Lumière de nuit"
          caption: "Plus doux le soir"
          onToggled: root.diva.runQuiet(["omarchy-toggle-nightlight"], "Lumière de nuit changée.")
        }
      }
    }

    Column {
      width: parent.width - switches.width - parent.spacing
      spacing: Style.space(10)
      DivaSlider {
        width: parent.width; diva: root.diva
        glyph: root.diva.state.muted ? "volume-off" : "volume-high"; label: "Volume"
        value: root.diva.state.volume
        dimmed: root.diva.state.muted === true
        onMoved: function(v) { root.diva.control("volume", v) }
      }
      DivaSlider {
        width: parent.width; diva: root.diva
        glyph: "sun"; label: "Luminosité"
        value: root.diva.state.brightness
        onMoved: function(v) { root.diva.control("brightness", Math.max(1, v)) }
      }
      Row {
        width: parent.width
        spacing: Style.space(8)
        Repeater {
          model: ["sound", "wallpaper", "lock", "reboot", "shutdown"]
          DivaButton {
            required property string modelData
            readonly property var action: Actions.byId(modelData)
            width: (parent.width - parent.spacing * 4) / 5
            implicitHeight: Style.space(54)
            radius: Style.space(20)
            diva: root.diva
            glyph: action.glyph
            stacked: true
            text: modelData === "sound" ? "Son" : modelData === "wallpaper" ? "Fond" : action.title
            primary: root.diva.pendingConfirm === "action:" + modelData
            onClicked: root.diva.activateTile(Actions.tile(action, 0))
          }
        }
      }
    }
  }
}
