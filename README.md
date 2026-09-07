# Pinokio (digasic) — Russian UI shell

Electron-оболочка для **[digasic/pinokiod](https://github.com/digasic/pinokiod)** (русский UI).

Upstream: [pinokiocomputer/pinokio](https://github.com/pinokiocomputer/pinokio).

## Версии

| | |
|--|--|
| Приложение (splash) | **8.2.0** |
| GitHub tag | **`v8.2.0+RU.v5`** |
| Релиз | https://github.com/digasic/pinokio/releases |

Артефакты: `Pinokio-RU-Setup.exe`, `Pinokio-RU-Portable.exe`.

## Sibling layout

```
pinokio-ru/
  pinokiod/   # digasic/pinokiod
  pinokio/    # this repo — "pinokiod": "file:../pinokiod"
```

```powershell
git clone https://github.com/digasic/pinokiod.git
git clone https://github.com/digasic/pinokio.git
cd pinokio
npm install
npx electron .
```

Документация i18n: [pinokiod/docs/I18N_RU.md](https://github.com/digasic/pinokiod/blob/main/docs/I18N_RU.md)

## Windows release build

```powershell
powershell -ExecutionPolicy Bypass -File scripts\dist-win-ru.ps1
powershell -ExecutionPolicy Bypass -File scripts\install-unpacked-ru.ps1   # NSIS /S
powershell -ExecutionPolicy Bypass -File scripts\smoke-installed-ru.ps1
```

Важное:

- `npmRebuild: true` + `scripts/patch-natives-gyp.js` (Spectre / MSB8040)
- `after-pack.js`: icon + natives + size gate
- `main.js`: `AppUserModelId = computer.pinokio`
- `minimal.js` (background): без Win toast / auto-openExternal

## Mode

- **desktop** — окно
- **background** — tray, UI в браузере

---

# Upstream README

Launch Anything.

# Script Policy

Pinokio is a 1-click launcher for any open-source project. Think of it as a terminal application with a user-friendly interface that can programmatically interact with scripts.

This means:

1. **Scripts can run anything:** Just like terminal apps can run shell scripts, Pinokio scripts can run any command, download files, and execute them. Essentially, Pinokio is a user-friendly terminal with a UI.
2. **How scripts can be run:** There are two ways to run scripts on Pinokio:
    1. **Write your own:** Just like writing and executing shell scripts in the terminal, you can create your own scripts and run them locally.
    2. **Install from the "Discover" page:** Vetted scripts are manually listed in the directory, tracked via Git, and frozen under the official GitHub organization. These are guaranteed to be secure and safe to install.
3. **Verified Scripts:** To be featured on the "Discover" page, scripts must go through the following strict process:
    1. **Publisher Verification:** You must be personally verified to submit scripts for consideration. Contact the Pinokio admin (https://x.com/cocktailpeanut) to request verification.
    2. **Github Organization Invitation:** Once verified, you'll be invited to the official Pinokio Factory GitHub organization as a contributor. Only members of this organization can publish scripts eligible for the "Discover" page. Abusing publishing privileges may result in removal from the organization.
    3. **Repository Transfer and Freeze** To apply for a feature, you must transfer your script repository to the Pinokio Factory GitHub organization. Follow this guide: https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository
    4. **Feature Application:** Once your repository is fully transferred and controlled by the organization, it is considered "frozen". You can then request to feature it on the "Discover" page by contacting the admin.
    5. **Review:** The script will be thoroughly reviewed and tested by the Pinokio admin. If verified as safe, it will be featured on the "Discover" page.
    6. **Troubleshooting:** If any issues arise after a script is featured, the Pinokio admin may:
        - Delist the script from the "Discover" page
        - Modify the script to resolve the issue. Since the script is under the Pinokio Factory organization, the admin has the rights to make necessary fixes.

# Security

## Scripts are isolated by design

By default all Pinokio scripts are stored run under an isolated location (at `~/pinokio/api`). Additionally, all binaries installed through the built-in package managers in Pinokio are installed within `~/pinokio/bin`. Basically, everything you do is stored inside `~/pinokio`. The risk factor is when a script intentionally tries to deviate away from this.

The script verification process checks to make sure this doesn't happen.

The Pinokio script syntax was designed to make this process simpler, both by human and machines.

## Scripts are open source

All scripts must be downloaded from public git repositories. The scripts are both human readable and machine readable (written in JSON syntax), so you can always check the source code before running it.
