# OpenCore Legacy Patcher — Sonoma on 2017 iMac

## Why do this

macOS Ventura (13) is the last officially supported release for the 2017 iMac. This blocks Xcode 16, which is required to build:

- **iPadOS 18** targets (the You-Sir Juan iOS kiosk app)
- **visionOS 2** targets (the spatial interface)
- RealityKit 4 APIs introduced in iPadOS 18

OpenCore Legacy Patcher (OCLP) is an open-source project that enables Sonoma (macOS 14) and Sequoia (macOS 15) on unsupported hardware. On the 2017 21.5-inch iMac, Sonoma is well-tested and stable for most users.

**Without OCLP:** This machine runs the full You-Sir Juan backend, web interface, and Ollama inference — but cannot build or run the iOS 18 simulator.

**With OCLP + Sonoma + Xcode 16:** Full development capability. Build the iOS kiosk app, run the iPad Pro simulator, build the visionOS target.

---

## What OCLP does and doesn't break

### Works after OCLP on 2017 iMac:
- Full macOS Sonoma / Sequoia functionality
- Docker Desktop
- Homebrew, Node.js, pnpm, Git
- Ollama (Intel CPU inference)
- All You-Sir Juan OS backend services
- Xcode 16 + iPadOS 18 Simulator
- Wi-Fi (may require OCLP root patch)
- Graphics acceleration (requires OCLP root patch post-install)

### Known limitations:
- Metal GPU acceleration requires OCLP root patch after install — without it, the UI runs in software rendering (slow but functional)
- Automatic macOS updates disabled (OCLP manages updates manually)
- Apple does not support this configuration

---

## Prerequisites

- 16 GB+ USB drive (32 GB recommended for the installer)
- Your current macOS Ventura data backed up (Time Machine or external drive)
- Apple ID (for Xcode download from App Store)
- Internet connection throughout

**Time required:** 2–3 hours total (mostly waiting for downloads and install)

---

## Step 1 — Download OpenCore Legacy Patcher

1. Go to: https://github.com/dortania/OpenCore-Legacy-Patcher/releases/latest
2. Download: `OpenCore-Patcher.app.zip`
3. Extract and open `OpenCore Patcher.app`

> Always use the latest OCLP release. Older versions may not patch the 2017 iMac correctly for newer macOS versions.

---

## Step 2 — Create the Sonoma installer USB

In the OCLP app:

1. Click **"Create macOS Installer"**
2. Select **"Download macOS Sonoma"** (or Sequoia if preferred)
   - Size: ~13 GB — allow 20–40 min depending on connection
3. When download completes, click **"Flash Installer"**
4. Select your USB drive
5. OCLP downloads macOS, creates a bootable USB, and patches it
6. When complete: **"OpenCore was successfully installed to the drive"**

---

## Step 3 — Install OpenCore to the USB

Still in OCLP:

1. Click **"Build and Install OpenCore"**
2. Select your USB drive as the target
3. OCLP builds an OpenCore EFI for your exact iMac model
4. Click **"Install to disk"** → select the USB

---

## Step 4 — Boot from USB and install Sonoma

1. Restart your iMac
2. Hold **Option (⌥)** during boot
3. Select the USB drive (labeled "EFI Boot" or the USB name)
4. In the OpenCore boot picker, select **"Install macOS Sonoma"**
5. Follow the macOS installer — choose "Upgrade" to keep your data, or erase for a clean install
6. Installation takes 30–60 minutes and several reboots

> During reboots: always hold Option (⌥) and select the USB EFI Boot until the install is complete.

---

## Step 5 — Post-install root patches (critical)

After Sonoma boots for the first time:

1. Open **OpenCore Patcher.app** (copy it to Applications from the USB or re-download)
2. Click **"Post-Install Root Patch"**
3. OCLP detects your hardware and shows required patches:
   - **AMD Legacy GCN Graphics** — restores Metal GPU acceleration for Radeon Pro 560
   - **Wi-Fi patches** — if your Wi-Fi chip needs it
4. Click **"Start Root Patching"** — requires admin password
5. Reboot when prompted

> **Skip this step and the UI will run in software rendering** — everything works but the interface feels sluggish. The root patch restores normal GPU-accelerated rendering.

---

## Step 6 — Install Xcode 16

Now on Sonoma, with GPU acceleration working:

1. Open the **App Store**
2. Search **Xcode**
3. Install (≈15 GB download)
4. Open Xcode, accept the license, and let it install command-line tools

---

## Step 7 — Build the You-Sir Juan iOS app

```bash
cd /path/to/yousirjuan/apps/yousirjuan-ios
xcodegen generate                    # regenerate .xcodeproj from project.yml
open YouSirJuan.xcodeproj            # opens Xcode
```

In Xcode:
- Select scheme: **YouSirJuan**
- Select destination: **iPad Pro 13-inch (M5)** or **iPad Pro 13-inch (M4)** simulator
- Press **⌘R** to build and run

The simulator will launch with the full You-Sir Juan kiosk interface — Face ID flow, Home World, Voice screen.

---

## Step 8 — Maintain OpenCore after macOS updates

When Apple releases a macOS update:

1. Check the OCLP GitHub releases page first — ensure the new OCLP version supports the update
2. Download the new OCLP version
3. Run **"Build and Install OpenCore"** → install to your internal drive (not USB)
4. Install the macOS update normally
5. Run **"Post-Install Root Patch"** again after the update

> Never install macOS updates on OCLP systems without checking OCLP compatibility first.

---

## Resources

| Resource | URL |
|---|---|
| OCLP GitHub | https://github.com/dortania/OpenCore-Legacy-Patcher |
| OCLP Discord | https://discord.gg/rqdPgH8xSN |
| Full guide | https://dortania.github.io/OpenCore-Legacy-Patcher/ |
| iMac 2017 compatibility notes | https://github.com/dortania/OpenCore-Legacy-Patcher/blob/main/docs/MODELS.md |

---

## After Sonoma + Xcode 16: full You-Sir Juan OS capability

| Capability | Before OCLP | After OCLP |
|---|---|---|
| Backend + web interface | ✅ | ✅ |
| Ollama voice inference | ✅ | ✅ |
| Build iOS 18 kiosk app | ❌ | ✅ |
| iPad Pro simulator | ❌ | ✅ |
| visionOS 2 target | ❌ | ✅ |
| RealityKit 4 development | ❌ | ✅ |
| Full GPU acceleration | ⚠️ (Ventura = fine) | ✅ (root patched) |
