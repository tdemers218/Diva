import QtQuick
import "core/Icons.js" as Icons

// One icon, centred by its ink. Icon glyphs in a text font sit unevenly in
// their character cell, so centring the cell leaves them visibly off; this
// measures what is actually drawn and centres that in a square box.
Item {
  id: root
  // Name of an icon in core/Icons.js.
  property string name: ""
  property string family: ""
  property real size: 16
  property color color: "white"

  width: Math.ceil(size * 1.15)
  height: width

  TextMetrics {
    id: ink
    font.family: root.family
    font.pixelSize: root.size
    text: root.name ? Icons.glyph(root.name) : ""
  }
  Text {
    id: mark
    text: ink.text
    color: root.color
    font: ink.font
    x: Math.round((root.width - ink.tightBoundingRect.width) / 2 - ink.tightBoundingRect.x)
    y: Math.round((root.height - ink.tightBoundingRect.height) / 2 - (mark.baselineOffset + ink.tightBoundingRect.y))
  }
}
