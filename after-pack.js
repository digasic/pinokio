const path = require('path')
const fs = require('fs')

function mustExist(filePath, label) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`[afterPack] missing ${label}: ${filePath}`)
  }
  return filePath
}

function findFirst(roots, relParts) {
  for (const root of roots) {
    const p = path.join(root, ...relParts)
    if (fs.existsSync(p)) return p
  }
  return null
}

module.exports = async (context) => {
  const chmodHandler = require('./chmod')
  const wrapLinuxLauncher = require('./wrap-linux-launcher')
  const patchLinuxArm64Natives = require('./patch-linux-arm64-natives')

  await chmodHandler(context)
  await wrapLinuxLauncher(context)
  await patchLinuxArm64Natives(context)

  const resources = path.join(context.appOutDir, 'resources')
  const unpacked = path.join(resources, 'app.asar.unpacked')
  const assets = path.join(resources, 'assets')

  // extraResources (tray + shell icons) — hard fail if dropped
  mustExist(path.join(assets, 'icon_small.png'), 'tray icon_small.png')
  mustExist(path.join(assets, 'icon.png'), 'assets/icon.png')
  mustExist(path.join(assets, 'icon.ico'), 'assets/icon.ico')

  if (context.electronPlatformName === 'win32') {
    const exe = path.join(context.appOutDir, 'Pinokio.exe')
    const icon = path.join(__dirname, 'build', 'icon.ico')
    mustExist(exe, 'Pinokio.exe')
    mustExist(icon, 'build/icon.ico')

    const rcedit = require('rcedit')
    try {
      await rcedit(exe, {
        icon,
        'version-string': {
          CompanyName: 'digasic',
          FileDescription: 'Pinokio (Russian UI)',
          ProductName: 'Pinokio',
          LegalCopyright: 'Pinokio / digasic RU fork',
        },
        'product-version': context.packager.appInfo.version,
        'file-version': context.packager.appInfo.version,
      })
      console.log('[afterPack] embedded win icon via rcedit:', icon)
    } catch (err) {
      throw new Error(`[afterPack] rcedit failed: ${err && err.message ? err.message : err}`)
    }

    const nativeRoots = [
      path.join(unpacked, 'node_modules'),
      path.join(unpacked, 'node_modules', 'pinokiod', 'node_modules'),
    ]

    const conpty = findFirst(nativeRoots, [
      '@homebridge',
      'node-pty-prebuilt-multiarch',
      'build',
      'Release',
      'conpty.node',
    ])
    const pty = findFirst(nativeRoots, [
      '@homebridge',
      'node-pty-prebuilt-multiarch',
      'build',
      'Release',
      'pty.node',
    ])
    const sqlite = findFirst(nativeRoots, [
      'better-sqlite3',
      'build',
      'Release',
      'better_sqlite3.node',
    ])
    const koffi =
      findFirst(nativeRoots, ['@koromix', 'koffi-win32-x64', 'koffi.node']) ||
      findFirst(nativeRoots, ['koffi', 'build', 'koffi.node'])

    if (!conpty && !pty) {
      throw new Error(
        '[afterPack] missing win node-pty natives (conpty.node / pty.node). Run: npx electron-builder install-app-deps'
      )
    }
    if (!sqlite) {
      throw new Error(
        '[afterPack] missing better_sqlite3.node under app.asar.unpacked. Run: npx electron-builder install-app-deps'
      )
    }
    if (!koffi) {
      console.warn('[afterPack] WARN: koffi.node not found (may still resolve via optional dep)')
    } else {
      console.log('[afterPack] koffi:', koffi)
    }

    console.log('[afterPack] natives OK:', {
      conpty: !!conpty,
      pty: !!pty,
      sqlite: !!sqlite,
    })

    // asar size sanity — contaminated builds were ~700MB
    const asarPath = path.join(resources, 'app.asar')
    mustExist(asarPath, 'app.asar')
    const asarMb = fs.statSync(asarPath).size / (1024 * 1024)
    if (asarMb > 250) {
      throw new Error(
        `[afterPack] app.asar too large (${asarMb.toFixed(1)} MB). Likely junk packed — check build.files excludes`
      )
    }
    console.log(`[afterPack] app.asar ${asarMb.toFixed(1)} MB`)
  }
}
