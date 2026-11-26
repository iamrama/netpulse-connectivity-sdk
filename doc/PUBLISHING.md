# Publishing to pub.dev

## Before the first release

1. Confirm `netpulse_connectivity_sdk` is still free on pub.dev.
2. Run `tool/verify.ps1` and resolve every failure.
3. Publish the first version manually with `dart pub publish`.
4. On the package's Admin tab on pub.dev, enable publishing from GitHub
   Actions for `iamrama/netpulse-connectivity-sdk` with tag pattern
   `v{{version}}`.
5. Change the example's `com.example` application and bundle identifiers if you
   plan to distribute it.

## Each release

1. Update the version in `pubspec.yaml`, `ios/netpulse_connectivity_sdk.podspec`, `CHANGELOG.md`
   and `example/lib/screens/about_screen.dart`.
2. Run `tool/verify.ps1` (Windows) or `tool/verify.sh` (macOS or Linux).
3. Confirm CI passes, including the iOS job.
4. Test on physical Android and iOS devices: toggle Wi-Fi, mobile data,
   airplane mode and VPN.
5. `dart doc --dry-run`
6. `dart pub publish --dry-run` and resolve every warning.
7. Commit, then push a `v<version>` tag to publish through GitHub Actions.
