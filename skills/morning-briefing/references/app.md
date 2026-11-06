# The iPhone app

The **Briefing** app downloads today's briefing from their repository and plays it with pause, 15-second skip, speed and Lock Screen controls. It sets a real alarm that rings even on silent; its button **Play briefing** stops the alarm and starts the news.

They build it themselves with Xcode on their Mac. It's free with a normal Apple ID; the only catch is that self-built apps stop opening after 7 days and need a one-minute reinstall ("Renew" below).

Needs: a Mac, an iPhone with **iOS 26 or newer** (Settings → General → About → iOS Version), a cable, their Apple ID. About 20 minutes plus the Xcode download.

Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` in front of every `xcodebuild` / `xcrun` command, because the Mac may still point to the plain command line tools. The project is `~/Documents/my-morning-briefing/ios/MorningBriefing.xcodeproj`.

## 1. Xcode

1. Check `ls -d /Applications/Xcode.app`. If it's missing: Mac App Store → search **Xcode** → **Get**. It's large; they can keep going with other things meanwhile.
2. When it's installed, they open Xcode once and accept what it asks to install (choose **iOS** if it asks for platforms). Then run `xcodebuild -checkFirstLaunchStatus || xcodebuild -runFirstLaunch`.

## 2. Sign in with their Apple ID

They press **Cmd + ,** in Xcode (or click **Xcode** in the menu bar at the very top of the screen → **Settings…**) → **Accounts** → **+** at the bottom left → **Apple Account** → sign in. They should see their name with **(Personal Team)**.

## 3. Make the app theirs

1. **Bundle identifier**: every app needs a unique one. Make it `com.<their-github-name, lowercase, letters and digits only>.morningbriefing` and replace `com.example.morningbriefing` in `ios/MorningBriefing.xcodeproj/project.pbxproj` and `ios/project.yml`.
2. **Team**: run `open ios/MorningBriefing.xcodeproj`. Then guide them:
   - In the left column, click the top entry **MorningBriefing** (blue icon).
   - In the middle under **TARGETS**, click **MorningBriefing**.
   - Tab **Signing & Capabilities** → tick **Automatically manage signing** → **Team**: their **(Personal Team)**.
   - Two red errors ("Communication with Apple failed", "No profiles were found") are **normal** until an iPhone is connected. Tell them so before they worry.
3. Read the team ID Xcode wrote: `grep -m1 DEVELOPMENT_TEAM ios/MorningBriefing.xcodeproj/project.pbxproj`, and put the same value into `ios/project.yml`.

## 4. Connect the iPhone

1. They connect it with the cable, unlock it, and tap **Trust** on "Trust this computer?" (then their passcode).
2. Find it: `xcrun devicectl list devices`. Note the identifier (UDID) of the one that says `connected`.
3. **Developer Mode**: iPhone Settings → **Privacy & Security** → scroll to the bottom → **Developer Mode** → on → restart → **Turn On** → passcode. If it's not in the list yet, it appears after the first build attempt in step 5; then come back here. Nothing else on the phone changes, and they can turn it off later.

## 5. Build and install

1. Build:
   ```
   xcodebuild -project ios/MorningBriefing.xcodeproj -scheme MorningBriefing -configuration Debug \
     -destination id=<UDID> -derivedDataPath ios/build \
     -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
   ```
   Show only errors and the final result.
2. **Before** you start it, warn them: their Mac will ask "codesign wants to access key … in your keychain". They type **the password they use to unlock their Mac** and click **Always Allow** (not just Allow). It may ask twice. If they clicked Deny or closed it, just build again.
3. If it says **Developer Mode disabled**, do step 4.3 and build again.
4. Install: `xcrun devicectl device install app --device <UDID> ios/build/Build/Products/Debug-iphoneos/MorningBriefing.app`.
5. Commit `ios/project.yml` and `ios/MorningBriefing.xcodeproj/project.pbxproj` ("iPhone app: my team and app ID") and push.

## 6. Open it on the iPhone

1. To find it: on the home screen, swipe down from the middle and type **Briefing** (green icon with a yellow sun).
2. The first time it says **Untrusted Developer**. iPhone Settings → **General** → **VPN & Device Management** → their Apple ID under *Developer App* → **Trust** → **Trust**.

## 7. A read-only key for the app

The app needs a key that can only read their briefing repository.

1. They open `https://github.com/settings/personal-access-tokens/new` (signed in to GitHub).
2. **Token name**: `Briefing iPhone`. **Expiration**: 1 year (suggest a calendar reminder). **Repository access**: *Only select repositories* → `my-morning-briefing`. **Permissions**: *Repository permissions* → **Contents** → **Read-only**. Nothing else.
3. **Generate token**, then copy it (it starts with `github_pat_`). Best: send it to their iPhone via AirDrop, Notes or their password manager. Never into this chat.
4. In the app's Settings: repository `<their-github-name>/my-morning-briefing`, paste the key, **Save and test**. They should see ✅ *Connected*. **Done**, then the yellow ▶︎: today's briefing plays. They lock the phone and try pause and skip on the Lock Screen.

## 8. The alarm

1. In the app: **Wake me with my briefing** → the iPhone asks to allow alarms → **Allow** → set the time; **Weekdays only** if they like.
2. Test: time two minutes from now, lock the phone, wait. When it rings: **Play briefing**. Then set their real wake-up time.
3. If they had another alarm automation in Shortcuts or a Clock alarm for this, turn those off so nothing rings or plays twice.
4. Remind them: the briefing is made in the hours before their wake-up time (`setup.md` step 5). If they change the alarm time a lot, the schedule should follow (`changes.md`, "Wake-up time").

Bonus: Shortcuts has a **Play Morning Briefing** action, and "Hey Siri, play my Briefing" works.

## Renew (every 7 days)

When the app stops opening (or before it does): they connect the iPhone and unlock it; you check the UDID with `xcrun devicectl list devices`, run the build from step 5 and install it. Settings and the alarm stay. Mention that the Apple Developer Program ($99 a year) would make it last a year, but it isn't needed.

## No Mac? The Shortcut fallback

Without a Mac they can't build the app, but they can still hear the briefing when their alarm stops (it can't be paused, though):

1. The read-only key from step 7.
2. Shortcuts app → **+** → name it **Morning Briefing** → actions:
   - **Get Contents of URL**: `https://api.github.com/repos/<name>/my-morning-briefing/contents/latest.mp3?ref=audio`, Method GET, Headers `Authorization` = `Bearer github_pat_…` and `Accept` = `application/vnd.github.raw`
   - **Set Volume** → 50 %
   - **Play Sound**
3. Shortcuts → **Automation** → **+** → **Alarm** → **Is Stopped** → their wake-up alarm → **Run Immediately** → the Morning Briefing shortcut.
4. To stop it early: open Shortcuts and tap the running shortcut.
