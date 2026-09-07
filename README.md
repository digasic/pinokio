# Pinokio (digasic) — Russian UI shell

Electron shell fork paired with **[digasic/pinokiod](https://github.com/digasic/pinokiod)** (Russian UI i18n).

Upstream: [pinokiocomputer/pinokio](https://github.com/pinokiocomputer/pinokio).

## Sibling layout (required for local `file:` dep)

```
pinokio-ru/
  pinokiod/     # https://github.com/digasic/pinokiod
  pinokio/      # this repo — "pinokiod": "file:../pinokiod"
```

```powershell
git clone https://github.com/digasic/pinokiod.git
git clone https://github.com/digasic/pinokio.git
cd pinokio
npm install --ignore-scripts
npx electron .
```

Docs: [pinokiod/docs/I18N_RU.md](https://github.com/digasic/pinokiod/blob/main/docs/I18N_RU.md)

## Patch stock Windows installer

```powershell
powershell -ExecutionPolicy Bypass -File ..\pinokiod\scripts\patch-installed-ru.ps1
```

## Mode / tray

- **desktop** — normal window (taskbar)
- **background** — tray-only (`minimal.js`), UI in browser

There is no separate “minimize window to tray” toggle.

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
