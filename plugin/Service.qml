import QtQuick
import Quickshell

// Independent loaders keep a failed overview from disabling Diva's
// companion, battery care, and screensaver (and vice versa).
Item {
  id: root
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  function say(text, duration) { if (companion.item) companion.item.say(text, duration) }
  function greet() { if (companion.item) companion.item.greet() }
  function petted() { if (companion.item) companion.item.petted() }
  function powered(text) { if (companion.item) companion.item.powered(text) }
  Loader { source: Qt.resolvedUrl("Desktop.qml") }
  Loader {
    id: companion
    source: Qt.resolvedUrl("Companion.qml")
    onLoaded: {
      item.shell = Qt.binding(function() { return root.shell })
      item.manifest = Qt.binding(function() { return root.manifest })
      item.omarchyPath = Qt.binding(function() { return root.omarchyPath })
    }
  }
}
