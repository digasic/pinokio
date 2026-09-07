const { app } = require('electron')
const Pinokiod = require("pinokiod")
const config = require('./config')
const pinokiod = new Pinokiod(config)

// Must match package.json build.appId / NSIS Start Menu shortcut AUMID.
// Wrong id → Windows toast/taskbar can't bind to shortcut → "Выбор приложения" (OpenWith.exe).
const APP_USER_MODEL_ID = 'computer.pinokio'
if (process.platform === 'win32') {
  try {
    app.setAppUserModelId(APP_USER_MODEL_ID)
  } catch (err) {
    console.warn('setAppUserModelId failed', err)
  }
}

if (process.platform === 'linux') {
  console.log('[PINOKIO DEBUG] Linux startup')
  console.log('[PINOKIO DEBUG] ELECTRON_OZONE_PLATFORM_HINT:', process.env.ELECTRON_OZONE_PLATFORM_HINT || '<unset>')
  console.log('[PINOKIO DEBUG] ELECTRON_DISABLE_GPU:', process.env.ELECTRON_DISABLE_GPU || '<unset>')
  console.log('[PINOKIO DEBUG] DISPLAY:', process.env.DISPLAY || '<unset>')
  console.log('[PINOKIO DEBUG] WAYLAND_DISPLAY:', process.env.WAYLAND_DISPLAY || '<unset>')
  console.log('[PINOKIO DEBUG] argv:', process.argv.join(' '))
  app.disableHardwareAcceleration()
}

let mode = pinokiod.kernel.store.get("mode") || "full"
//iprocess.env.PINOKIO_MODE = process.env.PINOKIO_MODE || 'desktop';
if (mode === 'minimal' || mode === 'background') {
  require('./minimal');
} else {
  require('./full');
}
