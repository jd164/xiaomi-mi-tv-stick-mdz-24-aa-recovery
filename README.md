# Xiaomi Mi TV Stick (1080p, MDZ-24-AA) Complete Recovery, Debloat & Performance Guide

A battle-tested, step-by-step recovery and performance optimization guide for the **Xiaomi Mi TV Stick 1080p (Model: MDZ-24-AA / codename: `aquaman`)** running Android TV 9.

This guide addresses real-world issues on this EOL (End-of-Life) device:
- **Continuous boot loops & crashing during startup.**
- **Solid green screen / pink artifacts during video playback or casting (Chromecast).**
- **Severe memory exhaustion (running out of the 1GB RAM) leading to thermal shutdowns.**
- **Bloatware and telemetry spam causing background crashes (`com.mitv.download.service`).**
- **Replacement of the heavy Google TV Launcher with an ultra-clean, ad-free launcher.**

---

## ⚠️ Important Compatibility Warning
This guide and its scripts are specifically for:
- **Xiaomi Mi TV Stick 1080p / FHD**
- **Model number:** `MDZ-24-AA`
- **SoC platform:** Amlogic S805Y (`aquaman`)

> **DO NOT** flash firmware meant for the 4K model (`MDZ-27-AA` / `soul` / Amlogic S905Y4). Doing so will permanently hard-brick your 1080p device.

---

## Part 1: Diagnosing Power & Hardware Traps

### 1. The Power Supply Pitfall (Root Cause of Initial Boot Loops)
The Mi TV Stick requires a **minimum of 5V / 1.0A (ideally 5V / 2.0A)** continuous power.
- **Never power the stick using the TV's built-in USB port.** TV USB ports typically deliver only `500mA (0.5A)`. When the stick boots up and initializes the GPU or Wi-Fi, it encounters brownouts (undervoltage), freezes, or boot loops endlessly.
- **Always use a wall-plug power adapter (5V/1A or 5V/2A)** connected directly to mains electricity.
- **Micro-USB Cable:** Ensure the cable is tight and in good condition. Worn connectors cause momentary micro-cuts that trigger reboots.

### 2. Physical Placement & Thermal Throttling
- The MDZ-24-AA has a sealed plastic body with no active cooling.
- If pressed flat against the hot back panel of a TV, it easily reaches 85°C–90°C and shuts down to protect the SoC.
- **Use an HDMI extension cable** to let the stick hang away from the TV chassis, ensuring adequate airflow.

---

## Part 2: Hardware Recovery (Recovery Mode)

If your device is stuck on the Mi logo and won't reach the system:

1. Disconnect the power cable from the Mi Stick.
2. Hold down the **`OK`** (center d-pad button) and **`Back`** buttons simultaneously on the remote.
3. While holding both buttons firmly and aiming close to the stick, plug the power cable back in.
4. Keep holding until the black **Android Recovery** screen appears.
5. Using the remote, highlight and select:
   * **`Wipe data / factory reset`** -> Select **`Yes`**.
   * *(Optional)* **`Wipe cache partition`**.
6. Select **`Reboot system now`**.

---

## Part 3: Connecting via ADB (No PC Cable Needed)

Because connecting the stick directly to a standard PC USB port starves it of power (leading to immediate brownout reboots), you must connect over **Wi-Fi**.

> **⚠️ Android 9 Limitation:**
> In Android TV 9, the native "Wireless Debugging" pairing menu does not exist (it was only introduced in Android 11). Standard USB debugging will not expose port `5555` over the network automatically on boot without a helper app.

### How to Enable ADB over Wi-Fi on Android 9:
1. On your TV, navigate to **Settings** (`⚙`) -> **Device Preferences** -> **About**.
2. Scroll down to **Build** and press the remote's center button **7 times** until it announces *"You are now a developer!"*.
3. Go back one level, open **Developer options**, and enable **USB debugging**.
4. Open the **Google Play Store** on the stick, search for and install **`ADB AppControl TV`**.
5. Open **ADB AppControl TV** on your TV, go to its built-in terminal/console, and execute:
   ```bash
   setprop service.adb.tcp.port 5555
   ```
   *(Note: Running `stop adbd` / `start adbd` requires root permissions which stock Android TV does not have. Simply **restart / reboot the stick** once after running `setprop` so `adbd` binds to port 5555 on startup).*
6. Note your stick's local IP under **Settings** -> **Network & Internet** (e.g., `192.168.1.100`).
7. Open a terminal / PowerShell on your computer (connected to the same Wi-Fi network) and run:
   ```bash
   adb connect <STICK_IP>:5555
   ```
8. On your TV screen, accept the prompt: **"Always allow from this computer"** -> **OK**.

---

## Part 4: Fixing the Solid Green Screen & Crash Loop

### The Root Cause:
When streaming DRM-protected video (e.g., NOS TV, Netflix, or Chromecast), the Amlogic HDMI transmitter (`amhdmitx0`) was auto-negotiating **YUV 4:4:4 at 12-bit Deep Color** (`cd = 6` / `444,12bit`). The Mali-450 GPU and memory bus on this stick cannot sustain this bitrate, causing a color-space collapse (solid green screen) and a kernel panic.

### The Fix via ADB & Display Settings:
You can verify and fix the color depth directly:
```bash
# Verify current HDMI attributes
adb shell "cat /sys/class/amhdmitx/amhdmitx0/attr"
# (If it displays 444,12bit or rgb,12bit, it will crash under DRM video load)
```

To configure stable 8-bit standard RGB color:
1. Open the Amlogic display settings activity:
   ```bash
   adb shell "am start -n com.android.tv.settings/com.droidlogic.tv.settings.display.DisplayActivity"
   ```
2. Navigate to **Screen Resolution**:
   * **Auto switch to best resolution:** Turn **`OFF`** (prevents the TV from renegotiating and forcing 12-bit Deep Color on boot).
   * **Display Mode:** Select **`1080p 50Hz`** (50Hz matches European broadcast standards like NOS TV, avoiding frame rate conversion overhead).
   * **Color Depth Settings:** Switch from *Enabled* to **`Disabled`** (`cd = 4` / 8-bit).
   * **Color Space Settings:** Set to **`RGB`** (`cs = 0`).
3. Confirm in the terminal:
   ```bash
   adb shell "cat /sys/class/amhdmitx/amhdmitx0/attr"
   # Output should now be: rgb,8bit
   ```

### Chromecast Stability (Google Cast vs AirScreen):
* If Google Cast (`com.google.android.apps.mediashell`) crashes or causes video pipeline failures, avoid the bloated `v3.72+` update:
  ```bash
  # Revert to clean baseline Chromecast version
  adb shell "pm uninstall com.google.android.apps.mediashell"
  ```
* Alternatively, install **AirScreen** from the Google Play Store (as recommended by the ExtremeSlimTV profile) for a lightweight, hardware-accelerated Cast/AirPlay receiver that handles DRM streams with a dedicated buffer.

### Fixing HDMI-CEC Handshake Boot Loops:
To prevent the stick from freezing during boot when negotiating with certain TVs:
```bash
adb shell "settings put global hdmi_control_enabled 0"
adb shell "settings put global hdmi_control_auto_wakeup_enabled 0"
adb shell "settings put global hdmi_control_auto_device_off_enabled 0"
adb shell "settings put global stay_on_while_plugged_in 3"
```

---

## Part 5: Replacing the Launcher with Stick Home (Android 9 Backport)

The official Google TV Launcher was updated to version `7.7+`, injecting full-screen ads, sponsored trailers, and recommendations for uninstalled apps, consuming over **200MB of RAM**.

Other third-party launchers often present hidden bottlenecks on the Mi TV Stick 1080p:
- The stock **ExtremeSlimTV** bundled a looping 15MB 720p video (`aerial.mp4`) that continuously occupied the stick's only hardware video decoder (`OMX.amlogic.avc.decoder.awesome`), depleting CMA memory (down to **6.6 MB**) and causing kernel panics / reboots whenever Chromecast or video streaming started.
- The ultra-minimalist open-source launcher [**stick-home**](https://github.com/mehmetemreak/stick-home) is designed specifically for low-end TV sticks. However, upstream `stick-home` targets `minSdkVersion 29` (Android 10), while the Mi TV Stick (MDZ-24-AA) runs Android 9 (SDK 28).

### The Solution: Stick Home Backported to Android 9 (`stick-home-android9.apk`)
We backported `stick-home` (v1.0.2) to run natively on Android 9 (SDK 28):
1. **Manifest Patch:** Lowered `minSdkVersion` and `targetSdkVersion` from `29` to `28`.
2. **DEX Bytecode Patch:** Safely replaced missing Android 10 APIs:
   - `AppOpsManager.unsafeCheckOpNoThrow(...)` in `UsageAccess.isGranted` -> cleanly returns `false`.
   - `PowerManager.getCurrentThermalStatus()` in `SystemStatusWidget.read` -> returns `0` (`THERMAL_STATUS_NONE`).
3. **Full PT-PT Translation & Portugal Localization:**
   - **Language:** 100% translated from Turkish to European Portuguese (greetings, date/clock, contextual menus, settings, status indicators).
   - **Sports & Leagues:** Pre-configured with **Liga Portugal** (`4344`), **Liga dos Campeões** (`4480`), **Premier League** (`4328`), and **La Liga** (`4335`) in Portuguese.
   - **Weather:** Open-Meteo configured with `language=pt` and Portugal city search defaults (ex: Lisboa).
4. **Footprint & Performance Comparison:**
   - **APK Size:** Only **~284 KB** (compared to 1.4MB for ExtremeSlimTV-Lite and 15.7MB for ExtremeSlimTV).
   - **RAM Usage (PSS):** Only **~19 MB** (with **0 KB Graphics/GPU decoder memory allocated**).
   - **Video Decoders:** 0 hardware video decoders consumed, leaving 100% of CMA memory free for streaming and Chromecast.
   - **Feature Highlights:** Minimalist grid/row, quick app launch, automatically clears recent tasks on return to Home to save RAM.

### Installation & Activation:
```bash
# 1. Install Stick Home (Android 9 backport)
adb install -r stick-home-android9.apk

# 2. Grant calendar permission (if needed for the date/time header)
adb shell pm grant io.github.mehmetemreak.stickhome android.permission.READ_CALENDAR

# 3. Make Stick Home the Sole Default & Remove Other Launchers
adb shell "pm uninstall --user 0 com.google.android.tvlauncher"
adb shell "pm uninstall --user 0 com.google.android.tvrecommendations"
adb shell "pm uninstall --user 0 com.kulwant.atvhome"
adb shell "pm uninstall --user 0 com.spocky.projengmenu"

# 4. Verify that the Home button directly maps to Stick Home
adb shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME"
# Target output: io.github.mehmetemreak.stickhome/.HomeActivity
```

---

## Part 6: Deep Debloat (Permanent Removal of Xiaomi Bloatware)

The crash logs revealed that Xiaomi's background services (`com.mitv.download.service`) were crashing in an endless loop with `NullPointerException`, eating CPU and memory.

Run the following commands to permanently uninstall these background packages for user 0:

```bash
# 1. Xiaomi bloatware, auto-installers and broken telemetry
adb shell "pm uninstall --user 0 com.mitv.download.service"
adb shell "pm uninstall --user 0 com.xiaomi.mitv.updateservice"
adb shell "pm uninstall --user 0 com.xiaomi.android.tvsetup.partnercustomizer"
adb shell "pm uninstall --user 0 com.mitv.milinkservice"
adb shell "pm uninstall --user 0 com.mitv.videoplayer"
adb shell "pm uninstall --user 0 com.xiaomo.tv.milegal"
adb shell "pm uninstall --user 0 android.autoinstalls.config.xiaomi.mibox3"
adb shell "pm uninstall --user 0 android.autoinstalls.config.xioami.mibox3"

# 2. Block background execution policies permanently
adb shell "cmd appops set com.mitv.download.service RUN_IN_BACKGROUND ignore"
adb shell "cmd appops set com.xiaomi.mitv.updateservice RUN_IN_BACKGROUND ignore"
adb shell "cmd appops set com.xiaomi.android.tvsetup.partnercustomizer RUN_IN_BACKGROUND ignore"

# 3. Disable redundant Google and system background services
adb shell "pm disable-user --user 0 com.google.android.marvin.talkback"
adb shell "pm disable-user --user 0 com.android.printspooler"
adb shell "pm disable-user --user 0 com.google.android.feedback"
adb shell "pm disable-user --user 0 com.google.android.tv.bugreportsender"
adb shell "pm disable-user --user 0 com.google.android.syncadapters.calendar"
adb shell "pm disable-user --user 0 com.android.providers.calendar"
adb shell "pm disable-user --user 0 com.google.android.tts"
adb shell "pm disable-user --user 0 com.google.android.partnersetup"
adb shell "pm disable-user --user 0 com.google.android.backdrop"
adb shell "pm disable-user --user 0 com.xm.webcontent"
adb shell "pm disable-user --user 0 com.google.android.tungsten.setupwraith"
adb shell "pm disable-user --user 0 com.android.wallpaperbackup"
adb shell "pm disable-user --user 0 com.android.sharedstoragebackup"
adb shell "pm disable-user --user 0 com.google.android.backuptransport"
adb shell "pm disable-user --user 0 com.android.dreams.basic"
adb shell "pm disable-user --user 0 com.droidlogic.SubTitleService"
adb shell "pm disable-user --user 0 com.android.captiveportallogin"
adb shell "pm disable-user --user 0 com.android.settings.intelligence"
adb shell "pm disable-user --user 0 com.android.location.fused"
```

> **Note on Critical Services Preserved:**
> - `com.google.android.katniss` (Google Assistant / Voice Search) and `com.google.android.speech.pumpkin` are **KEPT ACTIVE** so the remote's microphone works.
> - `com.google.android.apps.mediashell` is **KEPT ACTIVE** for Google Cast / Chromecast functionality.
> - `com.android.vending` & `com.google.android.gms` are **KEPT ACTIVE** to preserve DRM (Widevine L1) licenses required for streaming apps (NOS TV, Netflix, etc.).

---

## Part 7: System Performance & RAM Tuning

Execute these commands to optimize memory management and eliminate UI rendering lag:

```bash
# 1. Turn off window animations (massively eases GPU load)
adb shell "settings put global window_animation_scale 0"
adb shell "settings put global transition_animation_scale 0"
adb shell "settings put global animator_duration_scale 0"

# 2. Restrict background processes to a maximum of 2 apps
adb shell "settings put global background_process_limit 2"

# 3. Disable Play Store auto-updating (prevents random background spikes)
adb shell "settings put global auto_update_apps 0"

# 4. Silence error reporting and verification daemons
adb shell "settings put global package_verifier_enable 0"
adb shell "settings put global send_action_app_error 0"
adb shell "settings put global hidden_api_policy 1"
```

---

## Automation Script

You can run all the debloating and optimizations in one automated batch. See [`scripts/optimize-stick.ps1`](scripts/optimize-stick.ps1) or [`scripts/optimize-stick.sh`](scripts/optimize-stick.sh).

---

## Verification & Results

Check memory usage before and after:
```bash
adb shell "free -m"
```

| Metric | Stock State (Before) | Optimized State (After) |
| :--- | :--- | :--- |
| **Free RAM** | ~60 MB | **~285 MB** |
| **Hardware Video CMA Free** | 6.6 MB (99% exhausted) | **117 MB (100% available)** |
| **Swap / ZRAM Usage** | > 180 MB | **~40 MB – 70 MB** |
| **Home Launcher** | Google TV Ads (~200MB RAM) | **Stick Home (~19MB RAM, 284KB APK, 0 video overhead)** |
| **Background Crashes** | Persistent (`NullPointerException`) | **0 crashes** |
| **Chromecast & DRM Casting** | Crash / reboot loop / green screen | **Stable (Hardware decoder freed)** |
| **Microphone & Voice** | Working | **Preserved 100%** |
| **Widevine L1 DRM** | Working | **Preserved 100%** |

---

## License
MIT License. Feel free to use, modify, and share to keep older Android TV devices out of landfills!
