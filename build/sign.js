module.exports = async function () {
  // DEPRECATED / unused. Digasic Win builds set win.signAndEditExecutable=false and
  // omit signtoolOptions.sign so electron-builder SKIPS signing entirely.
  // A custom sign hook still forces the "signing with signtool.exe" code path
  // (even as a no-op) and was part of confusing long portable builds.
  return
}
