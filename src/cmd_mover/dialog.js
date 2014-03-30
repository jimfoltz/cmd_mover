function cbclick(o) {
  var val = o.checked.toString();
  window.location = "skp:toggle_observer@" + val;
}

function toggle() {
  window.location = "skp:toggle_observer";
}

function save_btn() {
  window.location = "skp:save_positions";
}
