'use strict'
/**
 * Create Start Menu shortcut with System.AppUserModel.ID via Electron shell.writeShortcutLink.
 * Avoids STG_E_ACCESSDENIED from raw IPropertyStore hacks.
 *
 * Usage (from pinokio/):
 *   node_modules\electron\dist\electron.exe scripts\write-start-shortcut.js
 * Env overrides: PINOKIO_EXE, PINOKIO_LNK, PINOKIO_ICO, PINOKIO_AUMID
 */
const path = require('path')
const fs = require('fs')
const { app, shell } = require('electron')

const aumid = process.env.PINOKIO_AUMID || 'computer.pinokio'
const exe =
  process.env.PINOKIO_EXE ||
  path.join(process.env.LOCALAPPDATA || '', 'Programs', 'Pinokio', 'Pinokio.exe')
const ico =
  process.env.PINOKIO_ICO ||
  path.join(path.dirname(exe), 'app.ico')
const lnk =
  process.env.PINOKIO_LNK ||
  path.join(
    process.env.APPDATA || '',
    'Microsoft',
    'Windows',
    'Start Menu',
    'Programs',
    'Pinokio.lnk'
  )

app.whenReady().then(() => {
  try {
    if (!fs.existsSync(exe)) throw new Error('missing exe: ' + exe)
    const cwd = path.dirname(exe)
    const iconPath = fs.existsSync(ico) ? ico : exe
    const ops = {
      target: exe,
      cwd,
      description: 'Pinokio (Russian UI)',
      appUserModelId: aumid,
      icon: iconPath,
      iconIndex: 0,
    }
    const operation = fs.existsSync(lnk) ? 'update' : 'create'
    const ok = shell.writeShortcutLink(lnk, operation, ops)
    if (!ok) {
      // fallback recreate
      if (fs.existsSync(lnk)) fs.unlinkSync(lnk)
      const ok2 = shell.writeShortcutLink(lnk, 'create', ops)
      if (!ok2) throw new Error('writeShortcutLink failed')
    }
    console.log('OK shortcut', lnk, 'AUMID=' + aumid)
    app.exit(0)
  } catch (err) {
    console.error('FAIL', err && err.message ? err.message : err)
    app.exit(1)
  }
})
