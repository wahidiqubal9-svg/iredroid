# IReDroid - Android Infrared Fuzzer

IReDroid is a free and open-source infrared remote control application for Android devices with IR blasters. Turn your Android device into a universal remote control for TVs, air conditioners, set-top boxes, and other infrared-controlled devices.

<img width="340" height="auto" alt="image" src="https://github.com/user-attachments/assets/3c237693-be8a-460c-82f8-3e36d9aad9ea" />
<br>
<img width="340" height="auto" alt="image" src="https://github.com/user-attachments/assets/d3505c35-449e-4f89-a488-41c2847490d9" />
<br>
<img width="340" height="auto" alt="image" src="https://github.com/user-attachments/assets/9cf54212-94a1-4892-92f1-c873a24eccfb" />


## Features

- You can add/modify/implement custom remotes.
- IReDroid uses Flipper Zero's database and has 1700+ devices.
- You can fuzz devices in a category.
- Built-in **Voltas AC** smart remote (mode / fan / temperature) with 11 code
  varieties, shown as a **full-screen digital remote** — pinch in with two
  fingers to close. All saved remotes appear together under the **Remotes** tab.
  The codes are also bundled under `ACs/Voltas` in the Flipper database.
- Built-in **Atomberg Fan** remote (Power, speeds 1-5, Boost, Timer, LED,
  Sleep), styled like the original white IR remote; codes from the bundled
  Flipper IRDB (`Fans/Atomberg`).

## Supported IR Protocols

- **NEC**: Most common protocol used by many manufacturers
- **NECext**: Extended NEC protocol
- **Raw**: Custom timing patterns for unsupported protocols

- **RC5**: Doesn't work properly. (Need to fix)
- **RC6**: Doesn't work properly. (Need to fix)

## Requirements

- Android device with infrared (IR) blaster
- Android 5.0 (API level 21) or higher
- IR transmitter permission

## Installation

### From F-Droid (Not available yet)
1. Add the F-Droid repository
2. Search for "IReDroid"
3. Install the app

### From Source
1. Clone this repository
2. Open in Android Studio or VS Code
3. Run `flutter build apk --release`
4. Install the generated APK

### Automatic builds (GitHub Actions + Obtainium)
Every push to `main`/`master` (or a `v*` tag) runs
[`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml), which builds
release APKs and attaches them to a GitHub Release. Track that repository in
[Obtainium](https://github.com/ImranR98/Obtainium) to install and auto-update.

To make updates install cleanly (stable signature), add these repository
**Secrets** (Settings → Secrets and variables → Actions):

- `KEYSTORE_BASE64` – base64 of your keystore (`.jks`), e.g. `base64 -w0 upload-keystore.jks`
- `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`

Create the keystore once with:
```sh
keytool -genkeypair -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
If the secrets are absent the workflow still builds, but the APK is signed with
the ephemeral debug key (updates may require an uninstall first).

## Building from Source

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Android SDK
- Android Studio or VS Code

### Build Steps
```bash
# Clone the repository
git clone <repository-url>
cd iredroid

# Get dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons:main

# Build APK
flutter build apk --release
```

### Required Permissions
- `android.permission.TRANSMIT_IR`: Required to send infrared signals

## Contributing

We welcome contributions! Please feel free to:
- Report bugs and issues
- Suggest new features
- Submit pull requests
- Improve documentation

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Disclaimer

IReDroid is provided "as is" without warranty. Use at your own risk. The developers are not responsible for any damage caused by the use of this application.

## Compatibility

Tested on devices with IR blasters including:
- Xiaomi phones with IR blaster

## Support

For support, bug reports, or feature requests, please open an issue on the project repository.

---

**Made with ❤️ by the open source community**
