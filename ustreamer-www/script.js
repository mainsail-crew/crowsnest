document.getElementById("reloadSVG").style.display = "inline";

function reloadSnapshot() {
  snapshotUrl =
    "./snapshot";
  document.getElementById("snapshotImg").src =
    snapshotUrl + "?" + new Date().getTime();
}
