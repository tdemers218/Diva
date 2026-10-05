import QtQuick
import qs.Commons

// What she typed, answered in sections. Each section has a heading and its
// own kind of card (ResultCard), so what a result does shows before it is
// read. Arrow keys move by what is on screen, not by list order.
Flickable {
  id: root
  property var diva
  // Card items by their place in diva.tiles, for arrow keys and scrolling.
  property var cards: ({})

  contentHeight: body.implicitHeight
  clip: true
  boundsBehavior: Flickable.StopAtBounds

  function register(index, item) { cards[index] = item }

  // Keep the selected card in view.
  function reveal(item) {
    var top = item.mapToItem(body, 0, 0).y
    if (top < contentY) contentY = Math.max(0, top - Style.space(28))
    else if (top + item.height > contentY + height) contentY = top + item.height - height + Style.space(8)
  }

  // The card just above or below the selected one, nearest sideways.
  function vertical(direction) {
    var from = cards[diva.selected]
    if (!from) return diva.selected
    var here = from.mapToItem(body, from.width / 2, from.height / 2)
    var best = -1, bestRow = Infinity, bestSide = Infinity
    for (var i = 0; i < diva.tiles.length; i++) {
      var item = cards[i]
      if (!item || i === diva.selected) continue
      var at = item.mapToItem(body, item.width / 2, item.height / 2)
      var down = (at.y - here.y) * direction
      if (down < Style.space(12)) continue
      var side = Math.abs(at.x - here.x)
      if (down < bestRow - Style.space(6) || (Math.abs(down - bestRow) <= Style.space(6) && side < bestSide)) {
        best = i
        bestRow = down
        bestSide = side
      }
    }
    return best < 0 ? diva.selected : best
  }

  Column {
    id: body
    width: root.width
    spacing: Style.space(12)

    Repeater {
      model: root.diva ? root.diva.sections : []
      Column {
        id: section
        required property var modelData
        width: body.width
        spacing: Style.space(6)

        Text {
          textFormat: Text.PlainText
          visible: section.modelData.title !== ""
          leftPadding: Style.space(4)
          text: section.modelData.title.toUpperCase()
          color: root.diva.soft
          font.family: root.diva.fontFamily
          font.pixelSize: Style.space(11)
          font.weight: Font.DemiBold
          font.letterSpacing: 0.8
        }
        Flow {
          width: parent.width
          spacing: section.modelData.id === "open" ? 0 : Style.space(8)
          Repeater {
            model: section.modelData.tiles
            ResultCard {
              required property var modelData
              diva: root.diva
              view: root
              tile: modelData
              look: section.modelData.id
              span: section.width
            }
          }
        }
      }
    }
  }
}
