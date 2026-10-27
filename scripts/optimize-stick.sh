#!/usr/bin/env bash
#
# Automated optimization and debloat script for Xiaomi Mi TV Stick (MDZ-24-AA).
#

DEVICE_IP="${1:-192.168.1.100}"

echo "Connecting to Mi Stick TV at $DEVICE_IP..."
adb connect "${DEVICE_IP}:5555"

echo "Applying System Performance & GPU tweaks..."
adb shell "settings put global window_animation_scale 0"
adb shell "settings put global transition_animation_scale 0"
adb shell "settings put global animator_duration_scale 0"
adb shell "settings put global background_process_limit 2"
adb shell "settings put global package_verifier_enable 0"
adb shell "settings put global send_action_app_error 0"
adb shell "settings put global hidden_api_policy 1"
adb shell "settings put global hdmi_control_enabled 0"
adb shell "settings put global hdmi_control_auto_wakeup_enabled 0"
adb shell "settings put global hdmi_control_auto_device_off_enabled 0"
adb shell "settings put global stay_on_while_plugged_in 3"

echo "Uninstalling Xiaomi bloatware & crash-causing services..."
PACKAGES_UNINSTALL=(
    "com.google.android.tvlauncher"
    "com.google.android.tvrecommendations"
    "com.mitv.download.service"
    "com.xiaomi.mitv.updateservice"
    "com.xiaomi.android.tvsetup.partnercustomizer"
    "com.mitv.milinkservice"
    "com.mitv.videoplayer"
    "com.xiaomo.tv.milegal"
    "android.autoinstalls.config.xiaomi.mibox3"
    "android.autoinstalls.config.xioami.mibox3"
)

for pkg in "${PACKAGES_UNINSTALL[@]}"; do
    adb shell "pm uninstall --user 0 $pkg"
done

echo "Disabling background permissions via AppOps..."
adb shell "cmd appops set com.mitv.download.service RUN_IN_BACKGROUND ignore"
adb shell "cmd appops set com.xiaomi.mitv.updateservice RUN_IN_BACKGROUND ignore"
adb shell "cmd appops set com.xiaomi.android.tvsetup.partnercustomizer RUN_IN_BACKGROUND ignore"
adb shell "cmd appops set com.android.vending RUN_IN_BACKGROUND ignore"
adb shell "cmd appops set com.netflix.ninja RUN_IN_BACKGROUND ignore"

echo "Disabling non-essential background services..."
PACKAGES_DISABLE=(
    "com.google.android.marvin.talkback"
    "com.android.printspooler"
    "com.google.android.feedback"
    "com.google.android.tv.bugreportsender"
    "com.google.android.syncadapters.calendar"
    "com.android.providers.calendar"
    "com.google.android.tts"
    "com.google.android.partnersetup"
    "com.google.android.backdrop"
    "com.xm.webcontent"
    "com.google.android.tungsten.setupwraith"
    "com.android.wallpaperbackup"
    "com.android.sharedstoragebackup"
    "com.google.android.backuptransport"
    "com.android.dreams.basic"
    "com.droidlogic.SubTitleService"
    "com.android.captiveportallogin"
    "com.android.settings.intelligence"
    "com.android.location.fused"
)

for pkg in "${PACKAGES_DISABLE[@]}"; do
    adb shell "pm disable-user --user 0 $pkg"
done

echo "Checking current RAM status..."
adb shell "free -m"

echo "Optimization complete!"
