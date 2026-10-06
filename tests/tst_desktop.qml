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
  readonly property var screen: ({x:0,y:0,width:1366,height:768})
  function win(address,x,y,w,h,extra) { return Object.assign({address:address,at:[x,y],size:[w,h],title:address,icon:"",monitor:"m"},extra||{}) }
  function test_map_keeps_every_window_in_proportion() {
    var m = Desktop.map([win("a",-1316,16,1322,703),win("b",22,16,659,703),win("c",697,16,653,344),win("d",697,376,653,343)],screen,{width:1270,height:460},0.2)
    compare(m.tiles.length,4)
    m.tiles.forEach(function(t) {
      fuzzyCompare(t.width/t.window.size[0],m.scale,0.0001)
      fuzzyCompare(t.height/t.window.size[1],m.scale,0.0001)
      verify(t.x>=0 && t.x+t.width<=m.width+0.001)
      verify(t.y>=0 && t.y+t.height<=m.height+0.001)
    })
    verify(m.width<=1270.001 && m.height<=460.001)
    verify(m.tiles[1].width<m.tiles[0].width)
  }
  function test_map_orders_columns_and_finds_stacks() {
    var m = Desktop.map([win("c",697,16,653,344),win("a",-1316,16,1322,703),win("d",697,376,653,343),win("b",22,16,659,703)],screen,{width:1270,height:460},0.2)
    compare(m.tiles.map(function(t) { return t.address }),["a","b","c","d"])
    compare(m.tiles.map(function(t) { return t.column }),[0,1,2,2])
    compare(m.tiles.map(function(t) { return t.row }),[0,0,0,1])
    compare(m.tiles.map(function(t) { return t.stacked }),[false,false,true,true])
    compare(m.columns,3)
  }
  function test_map_shows_where_the_screen_is() {
    var m = Desktop.map([win("a",-1316,16,1322,703),win("b",22,16,1328,703)],screen,{width:1270,height:460},0.2)
    fuzzyCompare(m.viewport.width,1366*m.scale,0.001)
    fuzzyCompare(m.viewport.x,1316*m.scale,0.001)
    fuzzyCompare(m.tiles[1].x,m.viewport.x+22*m.scale,0.001)
  }
  function test_long_ribbon_stays_legible_and_scrolls() {
    var list = []
    for (var i=0;i<12;i++) list.push(win("w"+i,16+i*1344,16,1328,703))
    var m = Desktop.map(list,screen,{width:1270,height:460},0.2)
    compare(m.scale,0.2)
    verify(m.width>1270)
  }
  function test_tab_group_is_one_tile() {
    var m = Desktop.map([win("a",16,44,800,675,{grouped:["a","b"],recent:3}),win("b",16,44,800,675,{grouped:["a","b"],recent:1}),win("c",832,16,500,703)],screen,{width:1270,height:460},0.2)
    compare(m.tiles.length,2)
    compare(m.tiles[0].address,"b")
    compare(m.tiles[0].members.map(function(w) { return w.address }),["a","b"])
    compare(m.tiles[1].members.length,1)
  }
  function test_floating_windows_sit_on_top_and_out_of_columns() {
    var m = Desktop.map([win("f",100,60,600,400,{floating:true}),win("a",16,16,1328,703)],screen,{width:1270,height:460},0.2)
    compare(m.tiles.map(function(t) { return t.address }),["a","f"])
    compare(m.tiles[1].column,-1); verify(m.tiles[1].floating); compare(m.columns,1)
  }
  function test_empty_workspace_still_has_a_screen() {
    var m = Desktop.map([],screen,{width:1270,height:460},0.2)
    compare(m.tiles.length,0); verify(m.width>0 && m.height>0)
  }
  function test_gallery_fits_and_keeps_proportions() {
    var list = [win("a",0,0,1328,703),win("b",0,0,659,703),win("c",0,0,400,300)]
    var g = Desktop.gallery(list,{width:1270,height:460})
    verify(!g.editable)
    g.tiles.forEach(function(t,i) {
      fuzzyCompare(t.width/t.height,list[i].size[0]/list[i].size[1],0.001)
      verify(t.x>=-0.001 && t.x+t.width<=1270.001 && t.y>=-0.001 && t.y+t.height<=460.001)
    })
  }
  function test_dock_follows_window_order() {
    var list = [{cls:"c",workspace:2,at:[0,0]},{cls:"b",workspace:1,at:[900,0]},{cls:"a",workspace:1,at:[-400,0]},{cls:"b",workspace:1,at:[-900,0]}]
    var dock = Desktop.dock(list,apps,["firefox.desktop"])
    compare(dock.map(function(g) { return g.id }),["firefox.desktop","b","a","c"])
    compare(dock[1].windows.map(function(w) { return w.at[0] }),[-900,900])
  }
  function test_shared_screens_are_found() {
    var m = Desktop.map([win("a",16,16,659,703),win("b",691,16,659,344),win("c",691,376,659,343),win("d",1366,16,1328,703),win("e",2710,16,659,703)],screen,{width:1270,height:460},0.2)
    var s = Desktop.screens(m,"")
    compare(s.length,1); compare(s[0].count,3); compare([s[0].first,s[0].second],[0,1])
    fuzzyCompare(s[0].width,(691+659-16)*m.scale,0.001)
    compare(Desktop.joinKind(m,"d","a"),"quarter")
    compare(Desktop.joinKind(m,"a","d"),"pair")
    compare(Desktop.joinKind(m,"d","e"),"pair")
    compare(Desktop.joinKind(m,"c","a"),"quarter")
    compare(Desktop.screens(m,"b")[0].count,2)
  }
  function test_full_screen_of_quarters_takes_no_more() {
    var m = Desktop.map([win("a",16,16,659,344),win("b",16,376,659,343),win("c",691,16,659,344),win("d",691,376,659,343),win("e",1366,16,1328,703)],screen,{width:1270,height:460},0.2)
    compare(Desktop.screens(m,"")[0].count,4)
    compare(Desktop.joinKind(m,"e","a"),"beside")
  }
  function test_what_a_window_can_be_pulled_out_of() {
    var m = Desktop.map([win("a",16,16,659,703),win("b",691,16,659,344),win("c",691,376,659,343),win("d",1366,16,1328,344),win("e",1366,376,1328,343),
                         win("f",2710,16,1328,703),win("g",4054,44,1328,675,{grouped:["g","h"]}),win("h",4054,44,1328,675,{grouped:["g","h"]})],screen,{width:1270,height:460},0.2)
    compare(Desktop.leaveKind(m,"a").kind,"screen")
    compare(Desktop.leaveKind(m,"c").kind,"screen")
    fuzzyCompare(Desktop.leaveKind(m,"c").rect.width,(691+659-16)*m.scale,0.001)
    compare(Desktop.leaveKind(m,"d").kind,"stack")
    fuzzyCompare(Desktop.leaveKind(m,"d").rect.height,703*m.scale,0.001)
    compare(Desktop.leaveKind(m,"f"),null)
    compare(Desktop.leaveKind(m,"g").kind,"tabs")
  }
  function test_drop_zones() {
    compare(Desktop.dropZone(20,200,400,400,false),"before")
    compare(Desktop.dropZone(380,200,400,400,false),"after")
    compare(Desktop.dropZone(200,200,400,400,false),"group")
    compare(Desktop.dropZone(200,360,400,400,false),"stack")
    compare(Desktop.dropZone(20,200,400,400,true),"group")
  }
  function test_widths_snap_to_tidy_fractions() {
    compare(Desktop.snapWidth(0.51),0.5)
    compare(Desktop.snapWidth(0.35),1/3)
    compare(Desktop.snapWidth(0.97),1)
    compare(Desktop.snapWidth(0.05),0.2)
    compare(Desktop.snapWidth(0.42),0.42)
    compare(Desktop.widthLabel(0.5),"La moitié")
    compare(Desktop.widthLabel(0.42),"42 %")
    compare(Desktop.nextWidth(0.5,1),2/3)
    compare(Desktop.nextWidth(0.5,-1),1/3)
    compare(Desktop.nextWidth(1,1),1)
    compare(Desktop.nextWidth(0.3,-1),1/3)
  }
  function test_controls_stay_in_diva() {
    compare(Actions.byId("wifi").effect,{type:"page",page:"network"})
    compare(Actions.byId("bluetooth").effect,{type:"page",page:"bluetooth"})
    compare(Actions.byId("sound").effect,{type:"page",page:"audio"})
  }
}
