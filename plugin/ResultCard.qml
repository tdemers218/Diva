import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.Commons
import "core/Icons.js" as Icons

// One result, drawn the way its section calls for (see Smart.SECTIONS):
//   answer    a wide note with the whole text
//   windows   a card with a live preview of the window
//   window    a small pill
//   do        a wide button: icon, name, what it acts on
//   open      an app icon with its name underneath
//   settings  a list row with its path
//   ask       a bar
// The frame is shared: the same glass, hairline and rose rim when selected.
Item {
  id: root
  property var diva
  property var view
  property var tile
  property string look: "do"
  // Width of the section it sits in.
  property real span: 600

  readonly property bool current: tile.flat === diva.selected
  // Applications, and windows of a known application, show its own icon.
  readonly property bool pictured: tile.kind === "app" || (tile.kind === "window" && tile.icon !== "")
  readonly property int gap: Style.space(8)
  // Each section has a tint of its own for its icons.
  readonly property color tint: look === "windows" || look === "window" ? "#c9b0ee"
                              : look === "settings" ? "#cfb2c2"
                              : look === "ask" ? "#f3c0d4" : diva.rose
  property real pop: 0

  width: look === "answer" || look === "settings" ? span
       : look === "windows" ? Math.floor((span - gap * 2) / 3)
       : look === "do" ? Math.floor((span - gap) / 2)
       : look === "open" ? Math.floor(span / 6)
       : look === "ask" ? Math.floor((span - gap) / 2)
       : pill.implicitWidth + Style.space(30)
  height: look === "answer" ? Math.max(Style.space(56), note.implicitHeight + Style.space(26))
        : look === "windows" ? Math.round((width - Style.space(16)) * 10 / 16) + Style.space(62)
        : look === "do" ? Style.space(58)
        : look === "open" ? Style.space(100)
        : look === "settings" ? Style.space(46)
        : look === "ask" ? Style.space(54)
        : Style.space(40)

  onCurrentChanged: if (current && view) view.reveal(root)
  Component.onCompleted: if (view) view.register(tile.flat, root)

  // The Wayland handle of a Hyprland window, for its preview.
  function toplevel(address) {
    var key = String(address || "").toLowerCase().replace(/^0x/, "")
    var match = Hyprland.toplevels.values.find(function(t) {
      return String(t.address || "").toLowerCase().replace(/^0x/, "") === key
    })
    return match ? match.wayland : null
  }

  SequentialAnimation {
    running: true
    PauseAnimation { duration: root.diva.ms(Math.min(root.tile.flat, 12) * 16) }
    NumberAnimation { target: root; property: "pop"; from: 0; to: 1; duration: root.diva.ms(190); easing.type: Easing.OutCubic }
  }

  // An inline icon chip: the app's own icon, or the section-tinted glyph.
  component Chip: Item {
    id: chip
    property real side: Style.space(36)
    property bool plain: false
    width: side
    height: side
    Rectangle {
      visible: !root.pictured && !chip.plain
      anchors.fill: parent
      radius: Style.space(12)
      color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.current ? 0.3 : 0.16)
    }
    Text {
      visible: !root.pictured
      anchors.centerIn: parent
      text: root.tile.glyph ? Icons.glyph(root.tile.glyph) : ""
      color: chip.plain ? root.tint : root.diva.ink
      font.family: root.diva.iconFamily
      font.pixelSize: chip.side * 0.56
    }
    Image {
      visible: root.pictured
      anchors.fill: parent
      anchors.margins: chip.side * 0.04
      sourceSize.width: width
      sourceSize.height: height
      asynchronous: true
      source: root.pictured ? root.diva.iconSource(root.tile.icon) : ""
    }
  }

  component Label: Text {
    textFormat: Text.PlainText
    color: root.diva.ink
    font.family: root.diva.fontFamily
    font.pixelSize: Style.space(13)
    font.weight: Font.Medium
    elide: Text.ElideRight
  }
  component Caption: Text {
    textFormat: Text.PlainText
    color: root.diva.soft
    font.family: root.diva.fontFamily
    font.pixelSize: Style.space(11)
    elide: Text.ElideRight
  }

  Rectangle {
    id: frame
    anchors.fill: parent
    anchors.margins: root.look === "open" ? 0 : Style.space(1)
    radius: root.look === "window" || root.look === "ask" ? height / 2
          : root.look === "settings" ? Style.space(14)
          : Style.space(20)
    // App icons stand on their own; everything else sits on glass.
    color: root.look === "open" ? (root.current ? root.diva.tileSelected : "transparent")
         : root.look === "answer" ? Qt.rgba(1, 1, 1, 0.11)
         : root.current ? root.diva.tileSelected : root.diva.tileColor
    border.width: root.current ? Style.space(1.5) : root.look === "open" ? 0 : 1
    border.color: root.current ? root.diva.rose : root.diva.hairline
    opacity: root.pop
    scale: (0.94 + 0.06 * root.pop) * (press.pressed ? 0.97 : 1)
    Behavior on scale { NumberAnimation { duration: root.diva.ms(100) } }
    Behavior on color { ColorAnimation { duration: root.diva.ms(120) } }
    Behavior on border.color { ColorAnimation { duration: root.diva.ms(120) } }

    // answer: a tip in full, or a sum.
    Row {
      visible: root.look === "answer"
      x: Style.space(14)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(12)
      Chip { anchors.verticalCenter: parent.verticalCenter }
      Column {
        id: note
        anchors.verticalCenter: parent.verticalCenter
        width: root.width - Style.space(80)
        spacing: Style.space(2)
        Label {
          width: parent.width
          text: root.tile.kind === "calc" ? root.tile.title : root.tile.title
          font.pixelSize: Style.space(root.tile.kind === "calc" ? 20 : 13)
          font.weight: Font.DemiBold
        }
        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: root.tile.kind === "calc" ? "Entrée pour copier le résultat." : (root.tile.text || "")
          color: root.diva.ink
          opacity: 0.9
          font.family: root.diva.voiceFamily
          font.pixelSize: Style.space(14)
          wrapMode: Text.WordWrap
        }
      }
    }

    // windows: what the window looks like right now.
    Column {
      visible: root.look === "windows"
      anchors.fill: parent
      anchors.margins: Style.space(8)
      spacing: Style.space(7)
      ClippingRectangle {
        width: parent.width
        height: Math.round(width * 10 / 16)
        radius: Style.space(13)
        color: Qt.rgba(0, 0, 0, 0.3)
        Chip { anchors.centerIn: parent; side: Style.space(44); visible: !shot.hasContent }
        ScreencopyView {
          id: shot
          anchors.fill: parent
          // Only while this card is on screen.
          captureSource: root.look === "windows" && root.diva.opened ? root.toplevel(root.tile.id) : null
          live: true
        }
      }
      Row {
        width: parent.width
        spacing: Style.space(8)
        Chip { side: Style.space(30); anchors.verticalCenter: parent.verticalCenter }
        Column {
          width: parent.width - Style.space(38)
          anchors.verticalCenter: parent.verticalCenter
          Label { width: parent.width; text: root.tile.title }
          Caption { width: parent.width; text: root.tile.caption || "" }
        }
      }
    }

    // window: a pill.
    Row {
      id: pill
      visible: root.look === "window"
      anchors.centerIn: parent
      spacing: Style.space(7)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.tile.glyph ? Icons.glyph(root.tile.glyph) : ""
        color: root.tint
        font.family: root.diva.iconFamily
        font.pixelSize: Style.space(17)
      }
      Label { anchors.verticalCenter: parent.verticalCenter; text: root.tile.title }
    }

    // do: a wide button.
    Row {
      visible: root.look === "do"
      x: Style.space(11)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(11)
      Chip { anchors.verticalCenter: parent.verticalCenter }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        width: root.width - Style.space(72)
        Label { width: parent.width; text: root.tile.title; font.pixelSize: Style.space(14) }
        Caption {
          width: parent.width
          visible: text !== ""
          text: root.tile.caption || (root.tile.learned ? "Appris avec mon assistante" : "")
        }
      }
    }

    // open: an app icon.
    Column {
      visible: root.look === "open"
      anchors.centerIn: parent
      width: parent.width - Style.space(6)
      spacing: Style.space(5)
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Style.space(54)
        height: width
        radius: Style.space(17)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.2)
        gradient: Gradient {
          GradientStop { position: 0; color: root.pictured ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0.96, 0.72, 0.82, 0.42) }
          GradientStop { position: 1; color: root.pictured ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0.72, 0.42, 0.56, 0.42) }
        }
        Chip { anchors.centerIn: parent; side: Style.space(root.pictured ? 40 : 46); plain: true }
      }
      Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.tile.title; font.pixelSize: Style.space(12) }
      Caption { width: parent.width; horizontalAlignment: Text.AlignHCenter; visible: !!root.tile.caption; text: root.tile.caption || "" }
    }

    // settings: a row, with where it lives.
    Item {
      visible: root.look === "settings"
      anchors.fill: parent
      Text {
        id: cog
        x: Style.space(14)
        anchors.verticalCenter: parent.verticalCenter
        text: root.tile.glyph ? Icons.glyph(root.tile.glyph) : ""
        color: root.tint
        font.family: root.diva.iconFamily
        font.pixelSize: Style.space(17)
      }
      Label {
        anchors.left: cog.right
        anchors.leftMargin: Style.space(12)
        anchors.right: where.left
        anchors.rightMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        text: root.tile.title
      }
      Caption {
        id: where
        anchors.right: arrow.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        text: root.tile.caption || ""
      }
      Text {
        id: arrow
        anchors.right: parent.right
        anchors.rightMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.glyph("arrow-right")
        color: root.diva.soft
        font.family: root.diva.iconFamily
        font.pixelSize: Style.space(15)
      }
    }

    // ask: a bar.
    Row {
      visible: root.look === "ask"
      x: Style.space(18)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(10)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.tile.glyph ? Icons.glyph(root.tile.glyph) : ""
        color: root.tint
        font.family: root.diva.iconFamily
        font.pixelSize: Style.space(19)
      }
      Label {
        anchors.verticalCenter: parent.verticalCenter
        width: root.width - Style.space(66)
        text: root.tile.title
        font.pixelSize: Style.space(14)
      }
    }

    // A shortcut Diva learned from her assistant.
    Text {
      visible: root.tile.learned === true
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: Style.space(8)
      text: Icons.glyph("star")
      color: root.diva.rose
      font.family: root.diva.iconFamily
      font.pixelSize: Style.space(12)
    }
  }

  MouseArea {
    id: press
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    // Only a pointer that actually moves takes the selection: where it
    // happened to rest must not override the best result.
    onPositionChanged: if (root.diva.selected !== root.tile.flat) {
      root.diva.selected = root.tile.flat
      root.diva.cancelConfirm()
    }
    onClicked: root.diva.activate(root.tile.flat)
  }
}
