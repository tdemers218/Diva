import QtQuick
import qs.Commons
import "core/Icons.js" as Icons

// Diva's settings, inside her menu: who she talks to, her AI assistant, how
// she looks, and the discreet door to Omarchy's own tools.
Flickable {
  id: root
  property var diva
  // The subscription in use, as bin/diva-ai --status describes it.
  readonly property var current: (diva && diva.aiStatus[diva.aiStatus.provider]) || ({})
  readonly property var models: current.models || []
  readonly property bool subscription: !diva || diva.aiStatus.provider !== "anthropic"

  contentHeight: body.implicitHeight
  clip: true
  boundsBehavior: Flickable.StopAtBounds

  component Section: Text {
    textFormat: Text.PlainText
    topPadding: Style.space(8)
    color: root.diva.rose
    font.family: root.diva.fontFamily
    font.pixelSize: Style.space(13)
    font.weight: Font.DemiBold
    font.letterSpacing: 0.6
  }

  component Note: Text {
    textFormat: Text.PlainText
    width: body.width
    color: root.diva.soft
    font.family: root.diva.fontFamily
    font.pixelSize: Style.space(12)
    wrapMode: Text.WordWrap
  }

  Column {
    id: body
    width: root.width
    spacing: Style.space(8)

    Section { text: "TOI" }
    DivaInput {
      width: parent.width; diva: root.diva
      label: "Ton prénom"; placeholder: "Pour te dire bonjour"
      value: String(root.diva.config.name || "")
      onCommitted: function(text) { root.diva.setSetting(["name"], text.trim()) }
    }

    Section { text: "MON ASSISTANTE" }
    DivaSwitch {
      width: parent.width; diva: root.diva
      label: "Assistante intelligente"
      caption: "Je réponds à tes questions et je comprends les demandes compliquées."
      checked: !(root.diva.config.ai && root.diva.config.ai.enabled === false)
      onToggled: function(value) { root.diva.setSetting(["ai", "enabled"], value) }
    }

    // Which subscription thinks for Diva. Both sign in through the browser.
    Note { visible: root.subscription; text: "Avec quel abonnement ?" }
    Row {
      visible: root.subscription
      width: parent.width
      spacing: Style.space(8)
      Repeater {
        model: [{ id: "claude", name: "Claude" }, { id: "chatgpt", name: "ChatGPT" }]
        Rectangle {
          id: choice
          required property var modelData
          readonly property var info: root.diva.aiStatus[modelData.id] || ({})
          readonly property bool current: root.diva.aiStatus.provider === modelData.id
          width: (parent.width - parent.spacing) / 2
          height: Style.space(54)
          radius: Style.space(18)
          color: current ? root.diva.tileSelected : root.diva.tileColor
          border.width: current ? Style.space(1.5) : 1
          border.color: current ? root.diva.rose : root.diva.hairline
          Behavior on color { ColorAnimation { duration: root.diva.ms(140) } }
          Column {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(1)
            Text {
              textFormat: Text.PlainText
              text: choice.modelData.name
              color: root.diva.ink
              font.family: root.diva.fontFamily
              font.pixelSize: Style.space(14)
              font.weight: Font.DemiBold
            }
            Text {
              textFormat: Text.PlainText
              text: !choice.info.cli ? "Pas installé sur cet ordinateur"
                : choice.info.loggedIn ? "Connectée" + (choice.info.plan ? " (" + choice.info.plan + ")" : "") : "Pas encore connectée"
              color: choice.info.loggedIn ? root.diva.rose : root.diva.soft
              font.family: root.diva.fontFamily
              font.pixelSize: Style.space(12)
            }
          }
          Text {
            visible: choice.current
            anchors.right: parent.right
            anchors.rightMargin: Style.space(16)
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.glyph("check")
            color: root.diva.rose
            font.family: root.diva.iconFamily
            font.pixelSize: Style.space(18)
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.diva.setProvider(choice.modelData.id) }
        }
      }
    }
    Row {
      visible: root.subscription
      spacing: Style.space(8)
      DivaButton {
        diva: root.diva; glyph: "account"
        text: root.diva.aiStatus.loggedIn ? "Changer de compte" : "Me connecter"
        primary: !root.diva.aiStatus.loggedIn
        enabled: root.diva.aiStatus.cli === true
        onClicked: root.diva.login()
      }
      DivaButton {
        diva: root.diva; glyph: "check"; text: "Tester"
        enabled: root.diva.aiStatus.loggedIn === true && !root.diva.thinking
        onClicked: root.diva.testAi()
      }
    }

    // The models of that subscription, and what each is best for.
    Note {
      visible: root.models.length > 0
      text: "Mon modèle de tous les jours. Pour un problème qui résiste, je mets mes lunettes et je passe sur "
            + (root.current.deep || "un modèle plus fort") + ", une fois par demande."
    }
    Repeater {
      model: root.models
      Rectangle {
        id: pick
        required property var modelData
        readonly property bool current: root.current.model === modelData.id
        width: body.width
        height: Math.max(Style.space(50), words.implicitHeight + Style.space(18))
        radius: Style.space(18)
        color: current ? root.diva.tileSelected : root.diva.tileColor
        border.width: current ? Style.space(1.5) : 1
        border.color: current ? root.diva.rose : root.diva.hairline
        Behavior on color { ColorAnimation { duration: root.diva.ms(140) } }
        Column {
          id: words
          anchors.left: parent.left
          anchors.leftMargin: Style.space(16)
          anchors.right: mark.left
          anchors.rightMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(1)
          Text {
            textFormat: Text.PlainText
            text: pick.modelData.name
            color: root.diva.ink
            font.family: root.diva.fontFamily
            font.pixelSize: Style.space(14)
            font.weight: Font.DemiBold
          }
          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: pick.modelData.best
            color: root.diva.soft
            font.family: root.diva.fontFamily
            font.pixelSize: Style.space(12)
            wrapMode: Text.WordWrap
          }
        }
        Text {
          id: mark
          anchors.right: parent.right
          anchors.rightMargin: Style.space(16)
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(18)
          text: pick.current ? Icons.glyph("check") : ""
          color: root.diva.rose
          font.family: root.diva.iconFamily
          font.pixelSize: Style.space(18)
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.diva.setModel(root.diva.aiStatus.provider, pick.modelData.id)
        }
      }
    }

    // The other way in, for an Anthropic API key (ai.provider = "anthropic").
    Row {
      visible: !root.subscription
      width: parent.width
      spacing: Style.space(8)
      DivaInput {
        id: keyField
        width: parent.width - saveKey.width - testKey.width - Style.space(16); diva: root.diva
        label: "Clé API"; password: true
        placeholder: root.diva.keyStored ? "Clé enregistrée (colle-en une autre pour la changer)" : "Colle ta clé ici (sk-ant-…)"
        onCommitted: function(text) { if (text.trim()) { root.diva.saveKey(text.trim()); keyField.clear() } }
      }
      DivaButton {
        id: saveKey
        anchors.verticalCenter: parent.verticalCenter
        diva: root.diva; text: "Enregistrer"; primary: true
        enabled: keyField.text.trim().length > 0
        onClicked: { root.diva.saveKey(keyField.text.trim()); keyField.clear() }
      }
      DivaButton {
        id: testKey
        anchors.verticalCenter: parent.verticalCenter
        diva: root.diva; glyph: "check"; text: "Tester"
        enabled: root.diva.keyStored && !root.diva.thinking
        onClicked: root.diva.testAi()
      }
    }
    Note {
      text: root.diva.settingsStatus !== "" ? root.diva.settingsStatus
        : !root.subscription ? "Colle une clé Anthropic (platform.claude.com, « API keys »). Elle reste sur cet ordinateur."
        : "« Me connecter » ouvre une page dans le navigateur : connecte-toi avec ton compte, c'est tout. " +
          "J'utilise ton abonnement, sans clé à copier."
      color: root.diva.settingsStatus !== "" ? root.diva.ink : root.diva.soft
    }

    Section { text: "APPARENCE" }
    Note { text: "Mon thème change les couleurs de tout l'ordinateur, avec ses propres fonds d'écran." }
    Flow {
      width: parent.width
      spacing: Style.space(8)
      Repeater {
        model: root.diva.themes
        Rectangle {
          id: swatch
          required property var modelData
          readonly property bool current: root.diva.theme === modelData.id
          width: (parent.width - parent.spacing * 2) / 3
          height: Style.space(62)
          radius: Style.space(18)
          color: modelData.background
          border.width: current ? Style.space(2) : 1
          border.color: current ? root.diva.rose : root.diva.hairline
          scale: tap.pressed ? 0.97 : 1
          Behavior on scale { NumberAnimation { duration: root.diva.ms(90) } }
          Row {
            x: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(10)
            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(22); height: width; radius: width / 2
              color: swatch.modelData.accent
            }
            Column {
              anchors.verticalCenter: parent.verticalCenter
              Text {
                textFormat: Text.PlainText
                text: swatch.modelData.name
                color: swatch.modelData.foreground
                font.family: root.diva.fontFamily
                font.pixelSize: Style.space(14)
                font.weight: Font.DemiBold
              }
              Text {
                textFormat: Text.PlainText
                text: swatch.modelData.mood
                color: swatch.modelData.foreground
                opacity: 0.7
                font.family: root.diva.fontFamily
                font.pixelSize: Style.space(11)
              }
            }
          }
          Text {
            visible: swatch.current
            anchors.right: parent.right
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.glyph("check")
            color: swatch.modelData.accent
            font.family: root.diva.iconFamily
            font.pixelSize: Style.space(17)
          }
          MouseArea { id: tap; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.diva.setTheme(swatch.modelData.id) }
        }
      }
    }
    DivaSwitch {
      width: parent.width; diva: root.diva
      label: "Animations"
      checked: root.diva.animate
      onToggled: function(value) { root.diva.setSetting(["animations"], value) }
    }
    DivaSwitch {
      width: parent.width; diva: root.diva
      label: "Écran de veille"
      caption: "Mon nom en rose, avec des bulles, des cœurs et des feux d'artifice, quand tu ne touches à rien."
      checked: root.diva.config.screensaver !== false
      onToggled: function(value) { root.diva.setSetting(["screensaver"], value) }
    }
    DivaSwitch {
      width: parent.width; diva: root.diva
      label: "Diva sur le bureau"
      caption: "Je reste dans un coin du fond d'écran, derrière tes fenêtres."
      checked: root.diva.config.companion !== false
      onToggled: function(value) { root.diva.setSetting(["companion"], value) }
    }
    Row {
      spacing: Style.space(8)
      DivaButton {
        diva: root.diva; glyph: "images"; text: "Choisir un fond d'écran"
        onClicked: root.diva.page = "appearance"
      }
    }

    Section { text: "BUREAU" }
    Note { text: "Les fenêtres défilent avec trois doigts. Quatre doigts vers le haut montrent tes espaces et toutes leurs fenêtres. Dans le dock, un clic retrouve l'application; un clic droit l'épingle ou la retire des favoris." }
    DivaSwitch {
      width: parent.width; diva: root.diva
      label: "Aperçu au bord supérieur"
      caption: "Garde la souris en haut de l'écran un court instant pour voir tes fenêtres."
      checked: root.diva.config.overviewHotEdge !== false
      onToggled: function(value) { root.diva.setSetting(["overviewHotEdge"], value) }
    }
    DivaButton {
      diva: root.diva; text: "Voir mes espaces"; glyph: "windows"
      onClicked: root.diva.runAndClose(["omarchy-shell", "diva.desktop", "show"])
    }

    Section { text: "BATTERIE" }
    Note {
      text: "Sur batterie, j'économise sans que ça se voie d'abord (ombres, flou), puis un peu plus quand elle baisse. Branchée, tout revient."
    }
    Row {
      width: parent.width
      spacing: Style.space(8)
      Repeater {
        model: [{ id: "auto", name: "Automatique" }, { id: "always", name: "Toujours économiser" }, { id: "off", name: "Jamais" }]
        DivaButton {
          required property var modelData
          width: (parent.width - parent.spacing * 2) / 3
          diva: root.diva
          text: modelData.name
          primary: ((root.diva.config.power && root.diva.config.power.mode) || "auto") === modelData.id
          onClicked: root.diva.setPowerMode(modelData.id)
        }
      }
    }

    Section { text: "AVANCÉ" }
    DivaSwitch {
      width: parent.width; diva: root.diva
      label: "Réglages Omarchy dans la recherche"
      caption: "Les réglages d'Omarchy apparaissent après mes réponses. Tape > pour ne voir qu'eux."
      checked: root.diva.showCommands
      onToggled: function(value) { root.diva.setSetting(["advancedSearch"], value) }
    }
    Flow {
      width: parent.width
      spacing: Style.space(8)
      DivaButton { diva: root.diva; glyph: "puzzle"; text: "Extensions"; onClicked: root.diva.page = "plugins" }
      DivaButton { diva: root.diva; glyph: "cog"; text: "Menu Omarchy"; onClicked: root.diva.runAndClose(["omarchy-menu", "summon", "root"]) }
      DivaButton { diva: root.diva; glyph: "update"; text: "Mises à jour"; onClicked: root.diva.runAndClose(["omarchy-menu", "summon", "update"]) }
      DivaButton {
        diva: root.diva
        glyph: "star"
        text: "Oublier mes " + root.diva.learned.length + " raccourcis appris"
        visible: root.diva.learned.length > 0
        onClicked: root.diva.forgetLearned()
      }
    }
    Item { width: 1; height: Style.space(4) }
  }
}
