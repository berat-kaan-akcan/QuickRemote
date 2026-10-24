# QuickRemote Privacy Policy

Last updated: October 22, 2026

> To fill in before publishing: **[DEVELOPER NAME]** and **[SUPPORT EMAIL]**. This page must be publicly reachable at the URL given as "Privacy policy" in Play Console.

QuickRemote turns your Android phone (and, optionally, your Wear OS watch) into a remote control for a presentation on your computer. This policy explains what the Android app (phone) and the watch app do with your data.

**In short:** QuickRemote sends no data to the developer. There are no accounts, no ads, no analytics and no crash reporting. Your phone talks only to your own computer, over your local network or Bluetooth.

## 1. Developer

**[DEVELOPER NAME]**, contact: **[SUPPORT EMAIL]**. Source code and issue tracker: https://github.com/berat-kaan-akcan/QuickRemote

## 2. What data goes where

### 2.1 To your computer (Wi-Fi mode)
The phone connects over your local network to the QuickRemote PC app running on your own computer. The connection is encrypted with TLS. The PC app makes its own certificate the first time it runs, and the phone recognises that certificate by its fingerprint (when you pair with the QR code, or when you compare the security code). The PC accepts connections only from local-network addresses.

Sent from the phone to the PC:
- The 6-digit PIN used for pairing.
- The device name: the name set in your Android settings, or the phone's model. The PC shows it in its list of connected phones.
- Remote commands: next/previous slide, start/end, black/white screen, laser and drawing movements, volume and media commands.

Sent from the PC to the phone: slide number and count, speaker notes, slide pictures (optional, can be turned off in Settings), the title of the playing media and the volume, error states, and the PC's host name. This data is kept in memory only and shown on screen.

None of this is sent to the developer or to any third party. It goes only to your own computer.

### 2.2 To your computer (Bluetooth mode)
In Bluetooth mode the phone appears to your computer as a Bluetooth keyboard and mouse. Only key presses and mouse movements go to the computer; the PC app is not needed. The app does not scan for nearby Bluetooth devices; it finds your computer by reading the list of devices you have already paired. If you press "Make phone visible", Android asks you to make the phone discoverable for a few minutes so that a computer can find it.

### 2.3 The watch app
The watch does not talk to the computer. It sends its commands (next/previous slide, black/white screen, laser movement) to QuickRemote on the phone through Google's Wear OS Wearable Data Layer, and the phone passes them to the computer. The phone sends the watch the connection state, the PC's name, the slide number and count, your theme choice, the talk's clock and its warnings. This travels between phone and watch through Google Play services; QuickRemote does not send it to any server. For the laser, an optional direct Bluetooth connection between watch and phone is used. The watch stores only your theme choice and whether a tip has been shown.

### 2.4 Camera
The camera is used only to read the pairing QR code on the PC screen, when you open the scanner. No picture is recorded, stored or sent anywhere. The Google ML Kit barcode model bundled in the app reads the QR code on the device. As described in its data disclosure, Google ML Kit may send usage and performance metrics (such as app version, device information, error and timing measurements) to Google; details: https://developers.google.com/ml-kit/android-data-disclosure . Your camera image is not part of those metrics. You can also connect by typing the IP address and PIN, in which case the camera is never opened.

## 3. What stays on the phone

The following stays on your phone, in the app's private storage. Android backup is turned off (`allowBackup=false`), so it does not enter cloud backups. It is removed when you uninstall the app or clear its data.
- Settings: language, theme, timer and vibration preferences, the selected program, and so on.
- The last computers you connected to (up to five): name, address, port and PIN. Shortcuts and the quick settings tile use them. Because the PC makes a new PIN each time it starts, old entries become invalid.
- The computers' certificate fingerprints (to check that the connection goes to the right computer).
- The history of the last 20 presentations: date, duration and time per slide. It is for you to look at only. "Copy report" copies it as text to the clipboard when you ask.
- An error log: `quickremote.log` in the app's private folder (three files of at most 1 MB). PINs, certificate fingerprints, `quickremote://` links, file paths, notes and media titles are removed before a line is written. The log is not sent anywhere.

## 4. Sharing you start yourself

- **Share error log:** writes the log to a temporary file and opens Android's share sheet. You decide where it goes.
- **Report a problem:** opens GitHub's new issue page in your browser with the app version, Android version and the program names on the PC filled in. Nothing is sent unless you submit it. GitHub's own privacy policy applies.

## 5. What we do not do

- No ads, and no advertising ID is used.
- No usage analytics, tracking or remote crash reporting.
- No accounts, sign-up or login.
- Location is not requested or used. Your contacts, files, photos and microphone are not accessed.
- Data is not sold, rented or shared with third parties.

## 6. Permissions and why

| Permission | Why |
|---|---|
| Camera | To read the pairing QR code. |
| Bluetooth (connect, discoverable; the old Bluetooth permissions before Android 12) | To make the phone a keyboard/mouse for the computer; to find the paired computer; the watch's laser link. |
| Notifications | The notification of the foreground service that runs while a remote is open. |
| Foreground service (connected device) and staying awake | To keep the connection while the phone locks. |
| Network access, Wi-Fi multicast | To find the computer on the local network and connect to it. |
| Vibration | Timer warnings. |

## 7. Children

QuickRemote is not directed at children and does not knowingly collect data from children; it collects data from nobody.

## 8. Your rights and deletion

The developer holds no data about you, so there is no account or server data to delete. You can remove what is stored on the phone by uninstalling the app or using Android Settings > Apps > QuickRemote > Storage > Clear data. You can remove a phone from the connected phones list on your computer.

## 9. Changes

If this policy changes, this page is updated and the date above changes. Important changes are noted in the release notes of the new app version.

## 10. Contact

**[SUPPORT EMAIL]** or https://github.com/berat-kaan-akcan/QuickRemote/issues
