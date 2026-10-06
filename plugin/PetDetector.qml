import QtQuick

// Notices a pointer being shaken from side to side: that is how Diva is
// petted. Feed it pointer positions; it emits `petted` after four quick
// changes of direction, then rests a moment.
QtObject {
  id: root
  // Sideways travel that counts as a stroke, in pixels.
  property real stroke: 5
  property real lastX: -1
  property int direction: 0
  property var turns: []
  property double restUntil: 0

  signal petted()

  function feed(x) {
    var now = Date.now()
    if (root.lastX < 0) { root.lastX = x; return }
    var dx = x - root.lastX
    if (Math.abs(dx) < root.stroke) return
    root.lastX = x
    var dir = dx > 0 ? 1 : -1
    if (dir === root.direction) return
    root.direction = dir
    if (now < root.restUntil) return
    var recent = root.turns.filter(function(t) { return now - t < 900 })
    recent.push(now)
    root.turns = recent
    if (recent.length >= 4) {
      root.turns = []
      root.restUntil = now + 1400
      root.petted()
    }
  }

  function forget() {
    root.lastX = -1
    root.direction = 0
    root.turns = []
  }
}
