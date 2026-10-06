.pragma library

function key(value) { return String(value || "").toLowerCase().replace(/\.desktop$/, "") }
function appFor(cls, apps) {
  var id = key(cls)
  var exact = apps.find(function(a) { return key(a.id) === id || key(a.startupClass) === id })
  if (exact) return exact
  var tail = id.split(".").pop()
  var matches = apps.filter(function(a) { return key(a.id).split(".").pop() === tail })
  return matches.length === 1 ? matches[0] : null
}
function dock(windows, apps, pins) {
  var groups = [], byId = Object.create(null)
  function add(id, app, pinned) {
    var k = key(id)
    if (byId[k]) { byId[k].pinned = byId[k].pinned || pinned; return byId[k] }
    var g = { id: id, name: app ? app.name : id, icon: app ? app.icon : "application-x-executable", pinned: pinned, windows: [], active: false }
    byId[k] = g; groups.push(g); return g
  }
  pins.forEach(function(id) { var a = appFor(id, apps); if (a) add(a.id, a, true) })
  windows.forEach(function(w) {
    var app = appFor(w.cls, apps)
    var g = add(app ? app.id : w.cls, app, false)
    g.windows.push(w); g.active = g.active || w.active
  })
  return groups
}
function magnification(distance, radius) {
  var t = Math.max(0, 1 - Math.abs(distance) / radius)
  return t * t * (3 - 2 * t)
}
function grid(count, width, height) {
  var best = { columns: 1, width: width, height: height }, area = -1
  for (var cols = 1; cols <= Math.max(1, count); cols++) {
    var rows = Math.ceil(Math.max(1, count) / cols)
    var w = Math.max(1, (width - (cols - 1) * 22) / cols)
    var h = Math.max(1, (height - (rows - 1) * 22) / rows)
    var score = Math.min(w, (h - 36) * 16 / 10)
    if (score > area) { area = score; best = {columns: cols, width: w, height: h} }
  }
  return best
}
