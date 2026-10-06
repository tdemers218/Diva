import QtQuick
import QtTest
import "../plugin/core/Desktop.js" as Desktop
import "../plugin/core/Actions.js" as Actions
TestCase {
  name: "DivaDesktop"
  readonly property var apps: [{id:"firefox.desktop",name:"Firefox",icon:"firefox"},{id:"org.gnome.Nautilus.desktop",name:"Fichiers",icon:"org.gnome.Nautilus"}]
  function test_pinned_running_apps_are_not_duplicated() {
    var dock = Desktop.dock([{cls:"firefox",active:true},{cls:"firefox",active:false},{cls:"org.gnome.Nautilus",active:false}],apps,["firefox.desktop"])
    compare(dock.length,2); compare(dock[0].windows.length,2); verify(dock[0].pinned); verify(dock[0].active)
    compare(dock[1].name,"Fichiers")
  }
  function test_unknown_app_is_still_accessible() {
    var dock = Desktop.dock([{cls:"custom-app",address:"0x1234"}],apps,[])
    compare(dock.length,1); compare(dock[0].windows[0].address,"0x1234")
  }
  function test_ambiguous_app_suffix_is_not_guessed() {
    compare(Desktop.appFor("Reader",[{id:"one.Reader"},{id:"two.Reader"}]),null)
  }
  function test_window_classes_cannot_collide_with_object_prototypes() {
    var result = Desktop.dock([{cls:"constructor"},{cls:"__proto__"}],[],[])
    compare(result.length,2)
    compare(result[0].windows.length,1)
    compare(result[1].windows.length,1)
  }
  function test_magnification_has_smooth_falloff() {
    compare(Desktop.magnification(0,100),1)
    compare(Desktop.magnification(100,100),0)
    compare(Desktop.magnification(50,100),Desktop.magnification(-50,100))
    verify(Desktop.magnification(20,100)>Desktop.magnification(60,100))
  }
  function test_overview_fits_every_window() {
    for (var count=1;count<=40;count++) {
      var g = Desktop.grid(count,1180,500)
      var rows = Math.ceil(count/g.columns)
      verify(g.columns*g.width+(g.columns-1)*22<=1180.001)
      verify(rows*g.height+(rows-1)*22<=500.001)
    }
  }
  function test_controls_stay_in_diva() {
    compare(Actions.byId("wifi").effect,{type:"page",page:"network"})
    compare(Actions.byId("bluetooth").effect,{type:"page",page:"bluetooth"})
    compare(Actions.byId("sound").effect,{type:"page",page:"audio"})
  }
}
