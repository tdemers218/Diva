import QtQuick
import QtQuick.Shapes

// A speech bubble drawn as one shape: the rounded body and its tail share a
// single outline, filled and stroked once, so translucency is even
// throughout and the tail never overlaps the body.
// `body` is where the text goes; it excludes the tail.
Item {
  id: root
  // Which side the tail points to: "left" or "right".
  property string side: "left"
  property color fill: Qt.rgba(1, 1, 1, 0.11)
  property color line: Qt.rgba(1, 1, 1, 0.13)
  property real radius: 20
  // How far the tail sticks out, and half its height.
  property real tail: 9
  readonly property real bodyX: side === "left" ? tail : 0
  readonly property real bodyWidth: Math.max(0, width - tail)

  // One closed path: around the body, out to the tail's tip and back. When
  // the body is a pill, the tail leaves from the curve of its end, so its
  // base is found on that arc rather than on a straight edge.
  readonly property string outline: {
    var w = width, h = height, t = tail
    var r = Math.max(0, Math.min(radius, h / 2, (w - t) / 2))
    var m = h / 2
    var s = Math.min(t, m)
    var up = m - s, down = m + s
    // How far the corner's curve has pulled in from the edge at height y.
    function inset(y) {
      var d = y < r ? r - y : y > h - r ? y - (h - r) : 0
      return r - Math.sqrt(Math.max(0, r * r - d * d))
    }
    function arc(x, y) { return " A " + r + " " + r + " 0 0 1 " + x + " " + y }
    if (side === "left") {
      var p = "M " + (t + r) + " 0 H " + (w - r) + arc(w, r) + " V " + (h - r) + arc(w - r, h) + " H " + (t + r)
      p += down >= h - r ? arc(t + inset(down), down) : arc(t, h - r) + " V " + down
      p += " L 0 " + m + " L " + (t + inset(up)) + " " + up
      p += up <= r ? arc(t + r, 0) : " V " + r + arc(t + r, 0)
      return p + " Z"
    }
    var b = w - t
    var q = "M " + r + " 0 H " + (b - r)
    q += up <= r ? arc(b - inset(up), up) : arc(b, r) + " V " + up
    q += " L " + w + " " + m + " L " + (b - inset(down)) + " " + down
    q += down >= h - r ? arc(b - r, h) : " V " + (h - r) + arc(b - r, h)
    return q + " H " + r + arc(0, h - r) + " V " + r + arc(r, 0) + " Z"
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 1
      strokeColor: root.line
      fillColor: root.fill
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: root.outline }
    }
  }
}
