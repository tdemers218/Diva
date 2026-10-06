import QtQuick
import qs.Commons
import qs.Ui

// Diva in the bar: her face and her name. She blinks and looks at the
// pointer when it is over her, and one click opens her menu.
BarWidget {
  id: root
  moduleName: "io.github.tdemers218.diva"

  readonly property int face: Math.round(root.barSize * 0.82)
  implicitWidth: root.vertical ? root.barSize : row.implicitWidth + dock.implicitWidth + Style.space(24)
  implicitHeight: root.vertical ? root.barSize + dock.implicitHeight : root.barSize

  Row {
    id: row
    anchors.left: parent.left
    anchors.leftMargin: Style.space(8)
    y: 0
    height: root.barSize
    spacing: Style.space(6)

    DivaAvatar {
      id: avatar
      anchors.verticalCenter: parent.verticalCenter
      width: root.face
      height: width
      // Still until the pointer comes: a bar should not redraw all day.
      animate: hover.hovered || greet.running
      mood: pressed.running ? "love" : hover.hovered ? "shy" : "idle"
      near: hover.hovered ? 0.7 : 0
      lookX: hover.hovered ? Math.max(-1, Math.min(1, (hover.point.position.x - root.width / 2) / (root.width / 2))) : 0
    }
    Text {
      visible: !root.vertical
      anchors.verticalCenter: parent.verticalCenter
      text: "Diva"
      color: hover.hovered ? "#eaa3c0" : (root.bar ? root.bar.barForeground : Color.foreground)
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      Behavior on color { ColorAnimation { duration: 150 } }
    }
  }

  Dock {
    id: dock
    x: root.vertical ? 0 : row.implicitWidth + Style.space(16)
    y: root.vertical ? root.barSize : 0
    barSize: root.barSize
    vertical: root.vertical
    edge: root.bar ? root.bar.position : "bottom"
  }

  HoverHandler {
    id: hover
    onPointChanged: petting.feed(point.position.x)
    onHoveredChanged: if (!hovered) petting.forget()
  }
  // Shake the pointer over her: she likes it here too.
  PetDetector {
    id: petting
    stroke: 3
    onPetted: { avatar.pet(); pressed.restart() }
  }
  // A wave when the bar appears.
  Timer { id: greet; interval: 2600; running: true; onTriggered: {} }
  Timer { id: pressed; interval: 900 }
  Component.onCompleted: avatar.hello()

  MouseArea {
    width: row.implicitWidth + Style.space(16)
    height: root.barSize
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      avatar.poke()
      pressed.restart()
      if (root.bar) root.bar.run("omarchy-shell shell toggle io.github.tdemers218.diva '{}'")
    }
  }
}
