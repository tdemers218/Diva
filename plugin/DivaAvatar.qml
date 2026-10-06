import QtQuick
import QtQuick.Shapes

// Diva herself: a small pink companion robot with a heart on her antenna
// and a face on her screen. She floats, blinks, follows the pointer with her
// eyes, leans in when it comes close, reacts to typing, and has moods:
//   idle, curious, thinking, happy, love, shy, sad, sleepy, focus.
// With `glasses` she is the little hacker: round glasses, a set mouth.
// Drawn on a 100 x 100 grid and scaled to whatever size she is given.
Item {
  id: root
  property string mood: "idle"
  property bool animate: true
  // Where she looks, -1..1 on each axis (0, 0 is straight ahead).
  property real lookX: 0
  property real lookY: 0
  // Round glasses, for when she thinks harder.
  property bool glasses: false
  // 0..1, how close the pointer is.
  property real near: 0
  readonly property real k: width / 100

  readonly property color shell: "#f3bfd4"
  readonly property color shellDark: "#d58bae"
  readonly property color shellEdge: "#fbe1ec"
  readonly property color screen: "#2a1926"
  readonly property color glow: "#ffe3ef"
  readonly property color heart: "#ff7fa8"
  readonly property bool eyesShut: mood === "happy" || mood === "sleepy"
  readonly property real ms: animate ? 1 : 0

  signal clicked()

  function hello() { if (animate) wave.restart() }
  // A keystroke: a tiny nod.
  function typed() { if (animate && !nod.running && !hop.running) nod.restart() }
  // Petted: she leans into it, with a couple of hearts.
  function pet() {
    if (!animate) return
    if (!hop.running) purr.restart()
    hearts.burst()
  }
  // A click on her: a hop and a burst of hearts.
  function poke() {
    if (!animate) return
    hop.restart()
    hearts.burst()
  }

  implicitWidth: 84
  implicitHeight: 84

  // Her shadow on the card; it tightens as she rises.
  Rectangle {
    x: 28 * root.k + body.lift * 0.3 * root.k
    y: 93 * root.k
    width: (44 + body.lift) * root.k
    height: 5 * root.k
    radius: height / 2
    color: Qt.rgba(0, 0, 0, 0.28)
  }

  Item {
    id: body
    width: parent.width
    height: parent.height
    transformOrigin: Item.Bottom
    // Vertical offset in grid units: floating, hops, nods.
    property real lift: 0
    property real jump: 0
    property real squish: 1
    y: (lift + jump) * root.k
    // She leans toward a pointer that comes close.
    rotation: root.lookX * root.near * 7
    scale: 1 + root.near * 0.05
    Behavior on scale { NumberAnimation { duration: 200 * root.ms; easing.type: Easing.OutCubic } }
    transform: Scale { origin.x: body.width / 2; origin.y: body.height; yScale: body.squish; xScale: 2 - body.squish }

    SequentialAnimation on lift {
      running: root.animate && root.visible
      loops: Animation.Infinite
      NumberAnimation { to: -3; duration: root.mood === "sleepy" ? 2600 : 1500; easing.type: Easing.InOutSine }
      NumberAnimation { to: 0; duration: root.mood === "sleepy" ? 2600 : 1500; easing.type: Easing.InOutSine }
    }

    SequentialAnimation {
      id: wave
      NumberAnimation { target: body; property: "rotation"; to: -12; duration: 130; easing.type: Easing.OutCubic }
      NumberAnimation { target: body; property: "rotation"; to: 10; duration: 170; easing.type: Easing.InOutSine }
      NumberAnimation { target: body; property: "rotation"; to: -5; duration: 150; easing.type: Easing.InOutSine }
      NumberAnimation { target: body; property: "rotation"; to: 0; duration: 140; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
      id: purr
      loops: 2
      NumberAnimation { target: body; property: "rotation"; to: -7; duration: 110; easing.type: Easing.InOutSine }
      NumberAnimation { target: body; property: "rotation"; to: 7; duration: 180; easing.type: Easing.InOutSine }
      NumberAnimation { target: body; property: "rotation"; to: 0; duration: 110; easing.type: Easing.InOutSine }
    }
    SequentialAnimation {
      id: nod
      NumberAnimation { target: body; property: "squish"; to: 0.955; duration: 60; easing.type: Easing.OutQuad }
      NumberAnimation { target: body; property: "squish"; to: 1; duration: 130; easing.type: Easing.OutBack }
    }
    SequentialAnimation {
      id: hop
      NumberAnimation { target: body; property: "squish"; to: 0.88; duration: 80; easing.type: Easing.OutQuad }
      ParallelAnimation {
        NumberAnimation { target: body; property: "squish"; to: 1.06; duration: 150; easing.type: Easing.OutQuad }
        NumberAnimation { target: body; property: "jump"; to: -13; duration: 170; easing.type: Easing.OutQuad }
      }
      NumberAnimation { target: body; property: "jump"; to: 0; duration: 190; easing.type: Easing.InQuad }
      NumberAnimation { target: body; property: "squish"; to: 0.93; duration: 70 }
      NumberAnimation { target: body; property: "squish"; to: 1; duration: 160; easing.type: Easing.OutBack }
    }

    // Antenna with a heart that sways, and pulses while she thinks.
    Item {
      id: antenna
      x: 50 * root.k; y: 19 * root.k
      width: 1; height: 1
      transformOrigin: Item.Bottom
      SequentialAnimation on rotation {
        running: root.animate && root.visible
        loops: Animation.Infinite
        NumberAnimation { to: 9; duration: 1100; easing.type: Easing.InOutSine }
        NumberAnimation { to: -9; duration: 1100; easing.type: Easing.InOutSine }
      }
      Rectangle {
        x: -1 * root.k; y: -11 * root.k
        width: 2 * root.k; height: 12 * root.k
        radius: width / 2
        color: root.shellDark
      }
      Shape {
        id: heartShape
        x: -8 * root.k; y: -24 * root.k
        width: 16; height: 15
        scale: root.k * heartShape.beat
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        property real beat: 1
        SequentialAnimation on beat {
          running: root.animate && (root.mood === "thinking" || root.mood === "love")
          loops: Animation.Infinite
          onStopped: heartShape.beat = 1
          NumberAnimation { to: 1.22; duration: 260; easing.type: Easing.OutQuad }
          NumberAnimation { to: 1; duration: 340; easing.type: Easing.InOutSine }
        }
        ShapePath {
          strokeWidth: -1
          fillColor: root.heart
          PathSvg { path: "M 8 14.5 C 2 10 0 7 0 4.4 C 0 1.8 2 0 4.2 0 C 5.8 0 7.2 0.9 8 2.3 C 8.8 0.9 10.2 0 11.8 0 C 14 0 16 1.8 16 4.4 C 16 7 14 10 8 14.5 Z" }
        }
      }
    }

    // Ears.
    Repeater {
      model: [6, 85]
      Rectangle {
        required property int modelData
        x: modelData * root.k; y: 44 * root.k
        width: 9 * root.k; height: 22 * root.k
        radius: 4.5 * root.k
        color: root.shellDark
      }
    }

    // Her shell, with a soft highlight.
    Rectangle {
      x: 12 * root.k; y: 20 * root.k
      width: 76 * root.k; height: 70 * root.k
      radius: 27 * root.k
      border.width: Math.max(1, 1.2 * root.k)
      border.color: root.shellEdge
      gradient: Gradient {
        GradientStop { position: 0; color: root.shell }
        GradientStop { position: 1; color: root.shellDark }
      }
      Rectangle {
        x: 9 * root.k; y: 5 * root.k
        width: 30 * root.k; height: 9 * root.k
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.45)
        rotation: -8
      }
    }

    // The screen her face lives on.
    Rectangle {
      id: face
      x: 21 * root.k; y: 33 * root.k
      width: 58 * root.k; height: 46 * root.k
      radius: 18 * root.k
      color: root.screen
      border.width: Math.max(1, 0.8 * root.k)
      border.color: Qt.rgba(1, 1, 1, 0.12)

      // Everything on the screen shifts a little with her gaze.
      Item {
        id: features
        width: parent.width
        height: parent.height
        x: root.lookX * 4.2 * root.k
        y: root.lookY * 3 * root.k + (root.mood === "thinking" ? -2.5 * root.k : 0)
        Behavior on x { NumberAnimation { duration: 110 * root.ms; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 110 * root.ms; easing.type: Easing.OutCubic } }

        // Cheeks.
        Repeater {
          model: [6, 43]
          Rectangle {
            required property int modelData
            x: modelData * root.k; y: 27 * root.k
            width: 9 * root.k; height: 5 * root.k
            radius: height / 2
            color: root.heart
            opacity: (root.mood === "shy" || root.mood === "love" ? 0.85 : root.mood === "happy" ? 0.65 : 0.35) + root.near * 0.25
            Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }
          }
        }

        // Eyes: glowing pills; hearts when she is smitten; arcs when shut.
        Repeater {
          model: [17, 41]
          Item {
            id: eye
            required property int modelData
            x: (modelData - 4.5) * root.k
            y: 12 * root.k
            width: 9 * root.k; height: 14 * root.k

            Rectangle {
              visible: !root.eyesShut && root.mood !== "love"
              anchors.centerIn: parent
              width: parent.width * (root.mood === "curious" ? 1.12 : 1)
              height: parent.height * blink.open * (root.mood === "curious" ? 1.12 : root.mood === "sad" ? 0.72 : root.mood === "focus" ? 0.6 : 1)
              radius: width / 2
              color: root.glow
              Behavior on width { NumberAnimation { duration: 160 * root.ms } }
            }
            // Lashes.
            Rectangle {
              visible: !root.eyesShut && root.mood !== "love" && blink.open > 0.6
              x: eye.modelData < 30 ? -1.6 * root.k : parent.width - 0.4 * root.k
              y: 0.5 * root.k
              width: 2 * root.k; height: 0.9 * root.k
              radius: height / 2
              rotation: eye.modelData < 30 ? 35 : -35
              color: root.glow
            }
            Shape {
              visible: root.eyesShut
              width: 9; height: 14
              scale: root.k
              transformOrigin: Item.TopLeft
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                strokeWidth: 2.4
                strokeColor: root.glow
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathSvg { path: root.mood === "sleepy" ? "M 0.5 8 Q 4.5 11 8.5 8" : "M 0.5 9 Q 4.5 3 8.5 9" }
              }
            }
            Shape {
              visible: root.mood === "love"
              x: -2 * root.k; y: 1 * root.k
              width: 16; height: 15
              scale: root.k * 0.82
              transformOrigin: Item.TopLeft
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                strokeWidth: -1
                fillColor: root.heart
                PathSvg { path: "M 8 14.5 C 2 10 0 7 0 4.4 C 0 1.8 2 0 4.2 0 C 5.8 0 7.2 0.9 8 2.3 C 8.8 0.9 10.2 0 11.8 0 C 14 0 16 1.8 16 4.4 C 16 7 14 10 8 14.5 Z" }
              }
            }
          }
        }

        // Glasses: two rims, a bridge, a glint.
        Item {
          visible: root.glasses
          opacity: root.glasses ? 1 : 0
          Repeater {
            model: [17, 41]
            Rectangle {
              required property int modelData
              x: (modelData - 9) * root.k; y: 9.5 * root.k
              width: 18 * root.k; height: 18 * root.k
              radius: width / 2
              color: Qt.rgba(0.75, 0.6, 1, 0.14)
              border.width: Math.max(1, 1.7 * root.k)
              border.color: "#d9c2ff"
              Rectangle {
                x: parent.width * 0.2; y: parent.height * 0.18
                width: parent.width * 0.22; height: parent.height * 0.1
                radius: height / 2
                rotation: -30
                color: Qt.rgba(1, 1, 1, 0.7)
              }
            }
          }
          Rectangle {
            x: 26 * root.k; y: 17.4 * root.k
            width: 6 * root.k; height: Math.max(1, 1.7 * root.k)
            radius: height / 2
            color: "#d9c2ff"
          }
        }

        // Mouth.
        Shape {
          x: 22 * root.k; y: 28 * root.k
          width: 14; height: 10
          scale: root.k
          transformOrigin: Item.TopLeft
          preferredRendererType: Shape.CurveRenderer
          visible: root.mood !== "thinking" && root.mood !== "curious"
          ShapePath {
            strokeWidth: 2.2
            strokeColor: root.glow
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg {
              path: root.mood === "sad" ? "M 3 6 Q 7 2.5 11 6"
                  : root.mood === "sleepy" || root.mood === "focus" ? "M 4.5 4.5 L 9.5 4.5"
                  : root.mood === "happy" || root.mood === "love" ? "M 2 2.5 Q 7 9.5 12 2.5"
                  : "M 3.5 3 Q 7 6.6 10.5 3"
            }
          }
        }
        Rectangle {
          visible: root.mood === "thinking" || root.mood === "curious"
          x: 26.6 * root.k; y: 29.5 * root.k
          width: 4.8 * root.k; height: 5.4 * root.k
          radius: width / 2
          color: root.glow
        }
      }
    }

    // A "z" that drifts up while she dozes.
    Text {
      id: zed
      visible: root.mood === "sleepy"
      x: 78 * root.k; y: 22 * root.k
      text: "z"
      color: root.glow
      font.pixelSize: 13 * root.k
      font.weight: Font.Bold
      SequentialAnimation on opacity {
        running: root.animate && root.mood === "sleepy"
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 0.9; duration: 900 }
        NumberAnimation { to: 0; duration: 900 }
      }
    }
  }

  // Hearts that fly up when she is clicked.
  Item {
    id: hearts
    anchors.fill: parent
    function burst() { for (var i = 0; i < flock.count; i++) flock.itemAt(i).fly() }
    Repeater {
      id: flock
      model: [{ dx: -26, delay: 0 }, { dx: 0, delay: 70 }, { dx: 24, delay: 140 }, { dx: -12, delay: 210 }, { dx: 14, delay: 260 }]
      Shape {
        id: one
        required property var modelData
        property real t: 1
        function fly() { rise.restart() }
        x: (42 + modelData.dx * t) * root.k
        y: (22 - 34 * t) * root.k
        width: 16; height: 15
        scale: root.k * (0.45 + 0.35 * t)
        opacity: t < 1 ? 1 - t * t : 0
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        SequentialAnimation {
          id: rise
          PauseAnimation { duration: one.modelData.delay }
          NumberAnimation { target: one; property: "t"; from: 0; to: 1; duration: 850; easing.type: Easing.OutCubic }
        }
        ShapePath {
          strokeWidth: -1
          fillColor: root.heart
          PathSvg { path: "M 8 14.5 C 2 10 0 7 0 4.4 C 0 1.8 2 0 4.2 0 C 5.8 0 7.2 0.9 8 2.3 C 8.8 0.9 10.2 0 11.8 0 C 14 0 16 1.8 16 4.4 C 16 7 14 10 8 14.5 Z" }
        }
      }
    }
  }

  // Blinks come at uneven moments, so she never looks mechanical.
  QtObject {
    id: blink
    property real open: 1
  }
  SequentialAnimation {
    id: blinkOnce
    NumberAnimation { target: blink; property: "open"; to: 0.1; duration: 70 }
    NumberAnimation { target: blink; property: "open"; to: 1; duration: 110 }
  }
  Timer {
    interval: 2600
    repeat: true
    running: root.animate && root.visible && !root.eyesShut
    onTriggered: {
      interval = 2000 + Math.random() * 3400
      blinkOnce.restart()
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
