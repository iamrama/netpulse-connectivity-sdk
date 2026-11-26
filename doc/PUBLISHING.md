# Publishing to pub.dev

## Before the first release

1. Confirm the name `netpulse` is free on pub.dev. If it is taken, rename the
   package.
2. Add your repository to `pubspec.yaml`:

   ```yaml
   repository: https://github.com/<owner>/netpulse
   issue_tracker: https://github.com/<owner>/netpulse/issues
   ```

3. Change the Android package `com.example.netpulse` to a domain you own. Update
   `android/build.gradle.kts` (`group`, `namespace`), `AndroidManifest.xml`, the
   Kotlin source folders and `package` lines, and `pubspec.yaml`
   (`flutter.plugin.platforms.android.package`). Delete the old folders.
4. Set `homepage` and `author` in `ios/netpulse.podspec`.
5. Change the example's `com.example` application and bundle identifiers if you
   plan to distribute it.

## Each release

1. Update the version in `pubspec.yaml`, `ios/netpulse.podspec`, `CHANGELOG.md`
   and `example/lib/screens/about_screen.dart`.
2. Run `tool/verify.ps1` (Windows) or `tool/verify.sh` (macOS or Linux).
3. Confirm CI passes, including the iOS job.
4. Test on physical Android and iOS devices: toggle Wi-Fi, mobile data,
   airplane mode and VPN.
5. `dart doc --dry-run`
6. `dart pub publish --dry-run` and resolve every warning.
7. `dart pub publish`
8. Tag the release.
