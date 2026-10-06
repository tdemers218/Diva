import QtQuick
import QtTest
import "../plugin" as Diva

TestCase {
  name: "Petting"

  Diva.PetDetector { id: detector }
  SignalSpy { id: petted; target: detector; signalName: "petted" }

  function init() {
    detector.forget()
    detector.restUntil = 0
    petted.clear()
  }

  function test_shaking_is_a_caress() {
    // Left, right, left, right, left: four changes of direction.
    var xs = [100, 130, 100, 130, 100, 130]
    for (var i = 0; i < xs.length; i++) detector.feed(xs[i])
    compare(petted.count, 1)
  }

  function test_moving_across_is_not() {
    for (var x = 100; x < 400; x += 20) detector.feed(x)
    compare(petted.count, 0)
  }

  function test_trembling_is_not() {
    // Smaller than a stroke: a resting hand.
    var xs = [100, 102, 100, 102, 100, 102, 100, 102]
    for (var i = 0; i < xs.length; i++) detector.feed(xs[i])
    compare(petted.count, 0)
  }

  function test_she_rests_between_caresses() {
    var xs = [100, 130, 100, 130, 100, 130, 100, 130, 100, 130, 100, 130]
    for (var i = 0; i < xs.length; i++) detector.feed(xs[i])
    compare(petted.count, 1)
  }

  function test_slow_back_and_forth_is_not() {
    detector.feed(100)
    detector.feed(130)
    wait(500)
    detector.feed(100)
    wait(500)
    detector.feed(130)
    wait(500)
    detector.feed(100)
    compare(petted.count, 0)
  }
}
