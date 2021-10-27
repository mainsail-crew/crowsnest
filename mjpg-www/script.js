document.getElementById("reloadSVG").style.display = "inline";

function reloadSnapshot() {
  snapshotUrl =
    "./?action=snapshot";
  document.getElementById("snapshotImg").src =
    snapshotUrl + "?" + new Date().getTime();
}