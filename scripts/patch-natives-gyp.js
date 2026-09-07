'use strict'
/**
 * @homebridge/node-pty-prebuilt-multiarch enables SpectreMitigation=Spectre.
 * VS Build Tools without Spectre libs → MSB8040. Disable for digasic Win builds.
 */
const fs = require('fs')
const path = require('path')

function patchFile(filePath) {
  if (!fs.existsSync(filePath)) return false
  let s = fs.readFileSync(filePath, 'utf8')
  const orig = s
  s = s.replace(/'SpectreMitigation'\s*:\s*'Spectre'/g, "'SpectreMitigation': 'false'")
  s = s.replace(/"SpectreMitigation"\s*:\s*"Spectre"/g, '"SpectreMitigation": "false"')
  s = s.replace(/<SpectreMitigation>Spectre<\/SpectreMitigation>/g, '<SpectreMitigation>false</SpectreMitigation>')
  if (s !== orig) {
    fs.writeFileSync(filePath, s)
    console.log('[patch-natives-gyp] patched', filePath)
    return true
  }
  return false
}

function findPtyRoots(appRoot) {
  const roots = []
  const candidates = [
    path.join(appRoot, 'node_modules', '@homebridge', 'node-pty-prebuilt-multiarch'),
    path.join(appRoot, 'node_modules', 'pinokiod', 'node_modules', '@homebridge', 'node-pty-prebuilt-multiarch'),
  ]
  // resolve junction
  for (const c of candidates) {
    if (fs.existsSync(c)) roots.push(c)
  }
  return [...new Set(roots.map((r) => fs.realpathSync(r)))]
}

const appRoot = path.resolve(__dirname, '..')
let n = 0
for (const root of findPtyRoots(appRoot)) {
  if (patchFile(path.join(root, 'binding.gyp'))) n++
  const buildDir = path.join(root, 'build')
  if (fs.existsSync(buildDir)) {
    for (const name of fs.readdirSync(buildDir)) {
      if (name.endsWith('.vcxproj')) {
        if (patchFile(path.join(buildDir, name))) n++
      }
    }
  }
}
if (n === 0) {
  console.warn('[patch-natives-gyp] nothing patched (module missing?)')
  process.exitCode = 0
} else {
  console.log('[patch-natives-gyp] files patched:', n)
}
