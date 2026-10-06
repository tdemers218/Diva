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
  windows.slice().sort(inOrder).forEach(function(w, i) {
    var app = appFor(w.cls, apps)
    var g = add(app ? app.id : w.cls, app, false)
    if (!g.windows.length) g.first = i
    g.windows.push(w); g.active = g.active || w.active
  })
  // Favourites that are not open come first, as launchers; what is open
  // follows in the order of the windows themselves, left to right.
  return groups.filter(function(g) { return !g.windows.length })
    .concat(groups.filter(function(g) { return g.windows.length }).sort(function(a, b) { return a.first - b.first }))
}
// Windows as they sit on the desktop: by workspace, then left to right along
// the ribbon, then top to bottom in a column.
function inOrder(a, b) {
  var p = a.at || [0, 0], q = b.at || [0, 0]
  return (a.workspace || 0) - (b.workspace || 0) || p[0] - q[0] || p[1] - q[1]
}
// An app's windows, the one used last first.
function byRecency(windows) {
  return windows.slice().sort(function(a, b) { return (b.active ? 1 : 0) - (a.active ? 1 : 0) || (a.recent || 0) - (b.recent || 0) })
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

// --- Overview map -----------------------------------------------------------

// Windows sharing a tab group are one tile; the member used most recently is
// the one Hyprland shows, so it stands for the group.
function tiles(windows) {
  var out = [], byKey = Object.create(null)
  windows.forEach(function(w) {
    var members = w.grouped && w.grouped.length > 1 ? w.grouped.slice() : [w.address]
    var k = members.slice().sort().join(",")
    var t = byKey[k]
    if (!t) { t = byKey[k] = { key: k, order: members, list: [] }; out.push(t) }
    t.list.push(w)
  })
  return out.map(function(t) {
    var shown = t.list.slice().sort(function(a, b) {
      return (b.active ? 1 : 0) - (a.active ? 1 : 0) || (a.recent || 0) - (b.recent || 0)
    })[0]
    var members = t.list.slice().sort(function(a, b) { return t.order.indexOf(a.address) - t.order.indexOf(b.address) })
    return { address: shown.address, window: shown, members: members }
  })
}

// One workspace drawn to scale: every window keeps its real proportions and
// its real place on the ribbon, so what is bigger on screen is bigger here.
// `view` is the screen rectangle, `area` the room available. When the ribbon
// is too long to stay legible, the scale stops at minScale and the map is
// wider than the area (the overview scrolls).
function map(windows, view, area, minScale) {
  var list = tiles(windows)
  var left = view.x, right = view.x + view.width
  list.forEach(function(t) {
    left = Math.min(left, t.window.at[0]); right = Math.max(right, t.window.at[0] + t.window.size[0])
  })
  var span = Math.max(1, right - left)
  var scale = Math.max(Math.min(area.width / span, area.height / Math.max(1, view.height)), minScale || 0)
  var tiled = list.filter(function(t) { return !t.window.floating }).sort(function(a, b) {
    return a.window.at[0] - b.window.at[0] || a.window.at[1] - b.window.at[1]
  })
  var column = -1, last = null, rows = []
  tiled.forEach(function(t) {
    if (last === null || t.window.at[0] - last > 8) { column++; rows.push(0) }
    last = t.window.at[0]; t.column = column; t.row = rows[column]++
  })
  var floating = list.filter(function(t) { return t.window.floating })
  var height = view.height * scale
  var result = tiled.concat(floating).map(function(t) {
    var w = t.window, h = w.size[1] * scale
    return {
      address: t.address, members: t.members, window: w, floating: !!w.floating,
      column: w.floating ? -1 : t.column, row: w.floating ? 0 : t.row,
      stacked: !w.floating && rows[t.column] > 1,
      x: (w.at[0] - left) * scale, y: Math.max(0, Math.min(height - h, (w.at[1] - view.y) * scale)),
      width: w.size[0] * scale, height: h,
      share: w.size[0] / Math.max(1, view.width)
    }
  })
  return { scale: scale, width: span * scale, height: height, columns: column + 1, tiles: result, editable: true,
           viewport: { x: (view.x - left) * scale, width: view.width * scale } }
}

// Windows of one application, from any workspace: there is no shared layout
// to draw, so they sit in an even grid, each still in its own proportions.
function gallery(windows, area) {
  var g = grid(windows.length, area.width, area.height)
  var rows = Math.ceil(Math.max(1, windows.length) / g.columns)
  var top = (area.height - rows * g.height - (rows - 1) * 22) / 2
  var result = windows.map(function(w, i) {
    var width = Math.min(g.width, g.height * w.size[0] / Math.max(1, w.size[1]))
    var height = width * w.size[1] / Math.max(1, w.size[0])
    return {
      address: w.address, members: [w], window: w, floating: !!w.floating, column: i % g.columns, row: 0, stacked: false,
      x: (i % g.columns) * (g.width + 22) + (g.width - width) / 2,
      y: top + Math.floor(i / g.columns) * (g.height + 22) + (g.height - height) / 2,
      width: width, height: height, share: 0
    }
  })
  return { scale: 0, width: area.width, height: area.height, columns: g.columns, tiles: result, editable: false,
           viewport: { x: 0, width: area.width } }
}

// A screen shared between windows: two neighbouring columns that are each
// about half a screen wide. Returned left to right as { first, second,
// count, x, y, width, height } in map coordinates; `without` leaves one
// window out, to see the layout as it will be once that window is moved.
function isHalf(share) { return share > 0.4 && share < 0.6 }
function screens(plan, without) {
  var columns = []
  plan.tiles.forEach(function(t) {
    if (t.floating || t.address === without) return
    var c = columns[t.column] || (columns[t.column] = { column: t.column, share: t.share, count: 0, x: t.x, y: t.y, right: t.x + t.width, bottom: t.y + t.height })
    c.count++; c.y = Math.min(c.y, t.y); c.bottom = Math.max(c.bottom, t.y + t.height); c.right = Math.max(c.right, t.x + t.width)
  })
  columns = columns.filter(function(c) { return !!c })
  var out = []
  for (var i = 0; i + 1 < columns.length; i++) {
    var a = columns[i], b = columns[i + 1]
    if (!isHalf(a.share) || !isHalf(b.share)) continue
    out.push({ first: a.column, second: b.column, counts: [a.count, b.count], count: a.count + b.count,
               x: a.x, y: Math.min(a.y, b.y), width: b.right - a.x, height: Math.max(a.bottom, b.bottom) - Math.min(a.y, b.y) })
    i++
  }
  return out
}
// What sharing a screen with `target` will do for the window `source`:
// "pair" (two halves), "quarter" (joins a shared screen) or "beside" (that
// screen is full, it starts the next one).
function joinKind(plan, source, target) {
  var t = plan.tiles.find(function(o) { return o.address === target })
  if (!t || t.floating) return ""
  var s = screens(plan, source).find(function(g) { return g.first === t.column || g.second === t.column })
  return !s ? "pair" : s.count < 4 ? "quarter" : "beside"
}

// What a window can be pulled out of: "tabs", a shared "screen", a plain
// "stack", or "" when it already has a place of its own. With it, the
// rectangle (map coordinates) the pointer has to leave for that to happen.
function leaveKind(plan, address) {
  var t = plan.tiles.find(function(o) { return o.address === address })
  if (!t || t.floating) return null
  var own = { x: t.x, y: t.y, width: t.width, height: t.height }
  if (t.members.length > 1) return { kind: "tabs", rect: own }
  var s = screens(plan, "").find(function(g) { return g.first === t.column || g.second === t.column })
  if (s) return { kind: "screen", rect: { x: s.x, y: s.y, width: s.width, height: s.height } }
  if (t.stacked) {
    var column = plan.tiles.filter(function(o) { return !o.floating && o.column === t.column })
    var top = Math.min.apply(null, column.map(function(o) { return o.y }))
    var bottom = Math.max.apply(null, column.map(function(o) { return o.y + o.height }))
    return { kind: "stack", rect: { x: t.x, y: top, width: t.width, height: bottom - top } }
  }
  return null
}

// What dropping a window at (x, y) on a tile of that size does: the sides
// place it before or after, the bottom stacks it underneath, the middle
// joins it ("group": a shared screen, or tabs when asked). Floating windows
// have no column, so they only join.
function dropZone(x, y, width, height, floating) {
  var fx = x / Math.max(1, width), fy = y / Math.max(1, height)
  if (floating) return "group"
  if (fx < 0.26) return "before"
  if (fx > 0.74) return "after"
  if (fy > 0.72) return "stack"
  return "group"
}

var WIDTHS = [1 / 3, 1 / 2, 2 / 3, 1]

// A width as a share of the screen, pulled to the nearest tidy fraction when
// it is close to one.
function snapWidth(share) {
  var s = Math.max(0.2, Math.min(1, share))
  for (var i = 0; i < WIDTHS.length; i++) if (Math.abs(s - WIDTHS[i]) < 0.045) return WIDTHS[i]
  return s
}
function widthLabel(share) {
  var i = WIDTHS.indexOf(share)
  return i >= 0 ? ["Un tiers", "La moitié", "Deux tiers", "Tout l'écran"][i] : Math.round(share * 100) + " %"
}
// The next tidy width up (step 1) or down (step -1) from the current one.
function nextWidth(share, step) {
  if (step > 0) { for (var i = 0; i < WIDTHS.length; i++) if (WIDTHS[i] > share + 0.03) return WIDTHS[i]; return 1 }
  for (var j = WIDTHS.length - 1; j >= 0; j--) if (WIDTHS[j] < share - 0.03) return WIDTHS[j]
  return WIDTHS[0]
}
