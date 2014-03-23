function cbclick(o) {
  var val = o.checked.toString();
  var b = document.getElementById('btn1');
  window.location = "skp:toggle_observer@" + val;
}

function toggle() {
  window.location = "skp:toggle_observer";
}

function save_btn() {
  window.location = "skp:remember_positions";
}
