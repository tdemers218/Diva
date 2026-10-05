import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs.Commons
import "core/Icons.js" as Icons

// Browse the Omarchy marketplace and manage installed plugins, through
// bin/diva-plugins (which only ever calls `omarchy plugin`). Categories,
// sorting, a verified-only switch, three preview sizes, and a detail view
// with the full-size picture. Listings come from plugins.omarchy.org and
// stay in their authors' words.
Item {
  id: root
  property var diva

  // "browse" (marketplace) or "installed".
  property string tab: "browse"
  property var results: []
  property var installed: []
  property var categories: []
  property int total: 0
  property int matches: 0
  property bool loading: false
  property bool working: false
  property string status: ""
  // "<verb>:<id or repo>" waiting for a second click.
  property string pending: ""
  // Filters.
  property string category: ""
  property string sort: "stars"
  property bool verifiedOnly: false
  property int limit: 60
  // Preview size: 0 list, 1 medium cards, 2 large cards.
  property int size: 1
  // The listing opened in the detail view, or null.
  property var detail: null

  readonly property var sortNames: ({ stars: "Les plus aimées", recent: "Les plus récentes", name: "De A à Z" })
  readonly property var sizeNames: ["Liste", "Aperçus moyens", "Grands aperçus"]
  readonly property int columns: size === 2 ? 2 : 3
  readonly property string warning: "Une extension peut tout faire sur l'ordinateur. Installe seulement ce en quoi tu as confiance."

  // Read when used: the menu hands itself over after bindings are set up.
  function helper() { return diva.pluginDir + "/bin/diva-plugins" }

  function load() {
    if (!diva) return
    if (lister.running) { reload.restart(); return }
    root.loading = true
    var argv = [root.helper(), "list", "--sort", root.sort, "--limit", String(root.limit)]
    if (root.category) argv = argv.concat(["--category", root.category])
    if (root.verifiedOnly) argv.push("--verified")
    lister.command = argv.concat(String(search.text).trim().split(/\s+/).filter(function(w) { return w.length > 0 }))
    lister.running = true
  }

  function loaded(text) {
    root.loading = false
    var r = null
    try { r = JSON.parse(String(text).trim()) } catch (e) { r = null }
    if (!r) { root.status = "Oups, je n'arrive pas à lire le catalogue."; return }
    root.installed = r.installed || []
    root.results = r.results || []
    root.categories = r.categories || []
    root.total = r.total || 0
    root.matches = r.matches || 0
    if (r.ok !== true) root.status = "Je n'arrive pas à joindre le catalogue. Vérifie Internet."
    else if (!root.working && !root.pending) root.status = ""
  }

  function filter(change) {
    change()
    root.limit = 60
    root.pending = ""
    root.load()
  }

  // Changes ask once: the first click arms the button, the second runs it.
  function act(verb, target, needsConfirm) {
    if (root.working) return
    var key = verb + ":" + target
    if (needsConfirm && root.pending !== key) {
      root.pending = key
      root.status = verb === "add" ? root.warning : "Clique encore pour confirmer."
      return
    }
    root.pending = ""
    root.working = true
    root.status = verb === "add" ? "Installation en cours…" : "Un instant…"
    job.command = [root.helper(), verb, target]
    job.running = true
  }

  function acted(text) {
    root.working = false
    var r = null
    try { r = JSON.parse(String(text).trim()) } catch (e) { r = null }
    root.status = r && r.ok === true ? "C'est fait." : "Ça n'a pas marché." + (r && r.message ? " " + r.message : "")
    root.load()
  }

  // The menu hands itself over just after this page is created.
  onDivaChanged: if (diva) { root.load(); search.focusField() }

  Process { id: lister; stdout: StdioCollector { onStreamFinished: root.loaded(text) } }
  Process { id: job; stdout: StdioCollector { onStreamFinished: root.acted(text) } }
  Timer { id: reload; interval: 250; onTriggered: root.load() }

  // A small filter chip.
  component Chip: Rectangle {
    id: chip
    property string text: ""
    property string glyph: ""
    property bool on: false
    signal clicked()
    implicitWidth: chipRow.implicitWidth + Style.space(22)
    implicitHeight: Style.space(30)
    radius: height / 2
    color: on ? root.diva.tileSelected : chipArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : root.diva.tileColor
    border.width: 1
    border.color: on ? root.diva.rose : root.diva.hairline
    Behavior on color { ColorAnimation { duration: root.diva.ms(120) } }
    Row {
      id: chipRow
      anchors.centerIn: parent
      spacing: Style.space(6)
      Text {
        visible: chip.glyph !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: chip.glyph ? Icons.glyph(chip.glyph) : ""
        color: root.diva.rose
        font.family: root.diva.iconFamily
        font.pixelSize: Style.space(14)
      }
      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: chip.text
        color: root.diva.ink
        font.family: root.diva.fontFamily
        font.pixelSize: Style.space(12)
        font.weight: Font.Medium
      }
    }
    MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
  }

  // A listing's picture, or its initials while there is none.
  component Preview: ClippingRectangle {
    id: shot
    property var listing
    property bool large: false
    radius: Style.space(14)
    color: Qt.rgba(1, 1, 1, 0.08)
    Text {
      textFormat: Text.PlainText
      anchors.centerIn: parent
      visible: picture.status !== Image.Ready
      text: String((shot.listing && shot.listing.name) || "?").slice(0, 2).toUpperCase()
      color: root.diva.rose
      font.family: root.diva.fontFamily
      font.pixelSize: Style.space(shot.large ? 34 : 18)
      font.weight: Font.DemiBold
    }
    Image {
      id: picture
      anchors.fill: parent
      source: !shot.listing ? "" : shot.large && shot.listing.image ? shot.listing.image : (shot.listing.thumb || "")
      sourceSize.width: shot.large ? 1600 : 720
      fillMode: shot.large ? Image.PreserveAspectFit : Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      opacity: status === Image.Ready ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: root.diva.ms(220) } }
    }
  }

  component InstallButton: DivaButton {
    property var listing
    diva: root.diva
    enabled: !!listing && !listing.installed && !root.working
    primary: !!listing && root.pending === "add:" + listing.repo
    glyph: listing && listing.installed ? "check" : "download"
    text: listing && listing.installed ? "Installée" : primary ? "Confirmer ?" : "Installer"
    onClicked: root.act("add", listing.repo, true)
  }

  Column {
    anchors.fill: parent
    spacing: Style.space(10)
    visible: root.detail === null

    Row {
      id: bar
      width: parent.width
      spacing: Style.space(8)
      DivaButton {
        diva: root.diva; text: "Découvrir"; primary: root.tab === "browse"
        onClicked: { root.tab = "browse"; root.pending = "" }
      }
      DivaButton {
        diva: root.diva; text: "Installées (" + root.installed.length + ")"; primary: root.tab === "installed"
        onClicked: { root.tab = "installed"; root.pending = "" }
      }
      DivaInput {
        id: search
        width: parent.width - x
        diva: root.diva
        placeholder: "Chercher une extension… (Entrée)"
        onCommitted: function(text) { root.tab = "browse"; root.filter(function() {}) }
      }
    }

    // Filters: how to sort, verified only, preview size.
    Row {
      id: tools
      visible: root.tab === "browse"
      width: parent.width
      spacing: Style.space(8)
      Chip {
        glyph: "star"; text: root.sortNames[root.sort]
        onClicked: root.filter(function() { root.sort = root.sort === "stars" ? "recent" : root.sort === "recent" ? "name" : "stars" })
      }
      Chip {
        glyph: "check"; text: "Vérifiées seulement"; on: root.verifiedOnly
        onClicked: root.filter(function() { root.verifiedOnly = !root.verifiedOnly })
      }
      Chip {
        glyph: "images"; text: root.sizeNames[root.size]
        onClicked: root.size = (root.size + 1) % 3
      }
    }

    // Categories, with how many listings each holds for this search.
    Flickable {
      id: chips
      visible: root.tab === "browse"
      width: parent.width
      height: Style.space(30)
      contentWidth: chipLine.implicitWidth
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.HorizontalFlick
      Row {
        id: chipLine
        spacing: Style.space(6)
        Chip { text: "Tout"; on: root.category === ""; onClicked: root.filter(function() { root.category = "" }) }
        Repeater {
          model: root.categories
          Chip {
            required property var modelData
            text: modelData.name + "  " + modelData.count
            on: root.category === modelData.name
            onClicked: root.filter(function() { root.category = root.category === modelData.name ? "" : modelData.name })
          }
        }
      }
      // The wheel scrolls the chips sideways.
      WheelHandler {
        onWheel: function(event) {
          chips.contentX = Math.max(0, Math.min(chips.contentWidth - chips.width, chips.contentX - event.angleDelta.y))
        }
      }
    }

    Text {
      id: info
      textFormat: Text.PlainText
      width: parent.width
      text: root.status !== "" ? root.status
        : root.loading ? "Je regarde le catalogue…"
        : root.tab === "installed" ? (root.installed.length ? "Tes extensions." : "Aucune extension installée pour l'instant.")
        : root.matches ? root.matches + " extensions" + (root.category ? " dans « " + root.category + " »" : "") + " sur " + root.total + ". Clique sur une image pour la voir en grand."
        : "Rien trouvé avec ces mots."
      color: root.status !== "" ? root.diva.ink : root.diva.soft
      font.family: root.diva.fontFamily
      font.pixelSize: Style.space(12)
      wrapMode: Text.WordWrap
    }

    // Marketplace, as cards or as a list.
    GridView {
      id: cards
      visible: root.tab === "browse"
      width: parent.width
      height: parent.height - bar.height - tools.height - chips.height - info.height - parent.spacing * 4
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      cellWidth: root.size === 0 ? width : Math.floor(width / root.columns)
      cellHeight: root.size === 0 ? Style.space(92) : Math.round(cellWidth * 9 / 16) + Style.space(96)
      model: root.results
      // More arrive as she nears the end.
      onAtYEndChanged: if (atYEnd && root.results.length >= root.limit && root.limit < 600 && !root.loading) {
        root.limit += 60
        root.load()
      }

      delegate: Item {
        id: cell
        required property var modelData
        required property int index
        width: cards.cellWidth
        height: cards.cellHeight
        // Cards fade up one after another.
        opacity: 0
        transform: Translate { id: rise; y: Style.space(12) }
        SequentialAnimation {
          running: true
          PauseAnimation { duration: root.diva.ms(Math.min(cell.index % 12, 9) * 28) }
          ParallelAnimation {
            NumberAnimation { target: cell; property: "opacity"; to: 1; duration: root.diva.ms(240) }
            NumberAnimation { target: rise; property: "y"; to: 0; duration: root.diva.ms(280); easing.type: Easing.OutCubic }
          }
        }

        Rectangle {
          anchors.fill: parent
          anchors.margins: Style.space(5)
          radius: Style.space(20)
          color: hover.hovered ? Qt.rgba(1, 1, 1, 0.12) : root.diva.tileColor
          border.width: 1
          border.color: root.diva.hairline
          Behavior on color { ColorAnimation { duration: root.diva.ms(120) } }
          HoverHandler { id: hover }

          Preview {
            id: shot
            listing: cell.modelData
            x: Style.space(8); y: Style.space(8)
            width: root.size === 0 ? Style.space(116) : parent.width - Style.space(16)
            height: root.size === 0 ? parent.height - Style.space(16) : Math.round(width * 9 / 16)
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.detail = cell.modelData }
          }

          Column {
            x: root.size === 0 ? shot.x + shot.width + Style.space(12) : Style.space(12)
            y: root.size === 0 ? Style.space(12) : shot.y + shot.height + Style.space(8)
            width: parent.width - x - (root.size === 0 ? install.width + Style.space(22) : Style.space(12))
            spacing: Style.space(2)
            // On a card, the first two lines leave room for the button beside them.
            readonly property int beside: root.size === 0 ? 0 : install.width + Style.space(8)
            Text {
              textFormat: Text.PlainText
              width: parent.width - parent.beside
              text: cell.modelData.name
              color: root.diva.ink
              font.family: root.diva.fontFamily
              font.pixelSize: Style.space(14)
              font.weight: Font.DemiBold
              elide: Text.ElideRight
            }
            Text {
              textFormat: Text.PlainText
              width: parent.width - parent.beside
              text: cell.modelData.stars + " étoiles" + (cell.modelData.verified ? "  ·  vérifiée" : "") + "  ·  " + cell.modelData.category
              color: root.diva.rose
              font.family: root.diva.fontFamily
              font.pixelSize: Style.space(11)
              elide: Text.ElideRight
            }
            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: cell.modelData.description
              color: root.diva.soft
              font.family: root.diva.fontFamily
              font.pixelSize: Style.space(12)
              wrapMode: Text.WordWrap
              maximumLineCount: 2
              elide: Text.ElideRight
            }
          }

          InstallButton {
            id: install
            listing: cell.modelData
            anchors.right: parent.right
            anchors.rightMargin: Style.space(10)
            y: root.size === 0 ? (parent.height - height) / 2 : shot.y + shot.height + Style.space(8)
          }
        }
      }
    }

    // What is installed.
    ListView {
      visible: root.tab === "installed"
      width: parent.width
      height: parent.height - bar.height - info.height - parent.spacing * 2
      clip: true
      spacing: Style.space(6)
      boundsBehavior: Flickable.StopAtBounds
      model: root.installed

      delegate: Rectangle {
        id: row
        required property var modelData
        width: ListView.view.width
        height: Style.space(62)
        radius: Style.space(18)
        color: root.diva.tileColor
        border.width: 1
        border.color: root.diva.hairline

        Column {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(16)
          anchors.right: buttons.left
          anchors.rightMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: row.modelData.name + (row.modelData.enabled ? "" : "   (désactivée)")
            color: root.diva.ink
            font.family: root.diva.fontFamily
            font.pixelSize: Style.space(14)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }
          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: row.modelData.id
            color: root.diva.soft
            font.family: root.diva.fontFamily
            font.pixelSize: Style.space(12)
            elide: Text.ElideRight
          }
        }
        Row {
          id: buttons
          anchors.right: parent.right
          anchors.rightMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(6)
          DivaButton {
            diva: root.diva; enabled: !root.working
            text: row.modelData.enabled ? "Désactiver" : "Activer"
            onClicked: root.act(row.modelData.enabled ? "disable" : "enable", row.modelData.id, false)
          }
          DivaButton {
            diva: root.diva; enabled: !root.working; glyph: "update"; text: "Mettre à jour"
            onClicked: root.act("update", row.modelData.id, false)
          }
          DivaButton {
            diva: root.diva; enabled: !root.working
            primary: root.pending === "remove:" + row.modelData.id
            text: primary ? "Confirmer ?" : "Supprimer"
            onClicked: root.act("remove", row.modelData.id, true)
          }
        }
      }
    }
  }

  // One listing, with its picture at full size.
  Item {
    anchors.fill: parent
    visible: root.detail !== null

    Preview {
      id: big
      listing: root.detail
      large: true
      width: parent.width
      height: parent.height - about.height - Style.space(12)
      radius: Style.space(20)
    }

    Row {
      id: about
      anchors.bottom: parent.bottom
      width: parent.width
      spacing: Style.space(12)

      Column {
        width: parent.width - actions.width - parent.spacing
        spacing: Style.space(3)
        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: root.detail ? root.detail.name : ""
          color: root.diva.ink
          font.family: root.diva.fontFamily
          font.pixelSize: Style.space(18)
          font.weight: Font.DemiBold
          elide: Text.ElideRight
        }
        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: !root.detail ? "" : "par " + root.detail.author + "  ·  " + root.detail.stars + " étoiles"
            + (root.detail.verified ? "  ·  vérifiée" : "") + (root.detail.version ? "  ·  version " + root.detail.version : "")
            + (root.detail.updated ? "  ·  mise à jour le " + root.detail.updated : "") + (root.detail.license ? "  ·  " + root.detail.license : "")
          color: root.diva.rose
          font.family: root.diva.fontFamily
          font.pixelSize: Style.space(12)
          elide: Text.ElideRight
        }
        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: root.pending && root.detail && root.pending === "add:" + root.detail.repo ? root.warning
              : root.detail ? root.detail.description : ""
          color: root.diva.soft
          font.family: root.diva.fontFamily
          font.pixelSize: Style.space(13)
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          elide: Text.ElideRight
        }
      }

      Row {
        id: actions
        anchors.bottom: parent.bottom
        spacing: Style.space(8)
        DivaButton { diva: root.diva; glyph: "arrow-left"; text: "Retour"; onClicked: { root.detail = null; root.pending = "" } }
        DivaButton {
          diva: root.diva; glyph: "link"; text: "Voir le code"
          onClicked: if (root.detail) Quickshell.execDetached(["omarchy-launch-browser", root.detail.repo])
        }
        InstallButton { listing: root.detail }
      }
    }
  }

  Keys.onEscapePressed: function(event) {
    if (root.detail !== null) { root.detail = null; root.pending = "" }
    else event.accepted = false
  }
}
