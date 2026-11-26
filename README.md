
# netpulse-connectivity-sdk

Offline-first connectivity intelligence for Flutter on Android and iOS.
No backend, no analytics, no account. Apache 2.0.

## Features

- Live connectivity stream and on-demand snapshots
- Internet verification (not only "is Wi-Fi on")
- Diagnostics: reachability, DNS, TCP, HTTP latency
- Quality score from 0 to 100
- Local, bounded history

## Requirements

Flutter 3.32+, Android 7.0 (API 24)+, iOS 13+.

## Install

```yaml
dependencies:
  netpulse: ^0.1.0
```

## Usage

```dart
import 'package:netpulse/netpulse.dart';

await NetPulse.initialize(
  const NetPulseConfig(probeEndpoint: 'https://example.com'),
);

final subscription = NetPulse.connectivityStream.listen(
  (state) => print('${state.connectionType.name} ${state.internetStatus.name}'),
  onError: (Object error) => print(error),
);

final now = await NetPulse.getCurrentState();
final report = await NetPulse.runDiagnostics();
final quality = await NetPulse.getNetworkQuality();
final events = await NetPulse.getHistory(
  since: DateTime.now().subtract(const Duration(hours: 24)),
);
await NetPulse.clearHistory();

await subscription.cancel();
await NetPulse.dispose();
```

## API

| Member | Behaviour |
| --- | --- |
| `initialize([config])` | Starts a session. Throws if one is active. |
| `dispose()` | Stops monitoring and closes the stream. Idempotent. |
| `connectivityStream` | Broadcast stream; replays the latest state to new listeners. |
| `getCurrentState()` | Fresh snapshot, verified if necessary. |
| `runDiagnostics({endpoint})` | Network failures are returned in the result. |
| `getNetworkQuality({maxAge})` | Reuses a measurement under one minute old by default. |
| `getHistory({since, limit})` | Newest first. |
| `clearHistory()` | Deletes stored events. |

All errors are `NetPulseException` with a `NetPulseErrorCode`.

## Configuration

| Option | Default |
| --- | --- |
| `probeEndpoint` | `https://example.com` |
| `enableMonitoring` | `true` |
| `verifyInternetAccess` | `true` |
| `recheckInterval` | 15 s (`Duration.zero` disables) |
| `timeout` | 5 s |
| `diagnosticSamples` | 5 |
| `persistHistory` | `true` |
| `maxHistoryEntries` | 500 |
| `historyRetention` | 30 days |

The default endpoint is a public example domain meant for illustration. In
production, set `probeEndpoint` to a small URL you control that answers `HEAD`
with a 2xx or 3xx status.

## How results are determined

| | Android | iOS |
| --- | --- | --- |
| Source | `ConnectivityManager` default network | `NWPathMonitor` |
| Internet status | OS validation, else probe | Probe |
| Captive portal | Reported | Not reported |
| VPN flag | Reported | `null` |

Quality score: latency 50% (100 at 50 ms or less, 0 at 1000 ms), failed samples
35% (0 at half lost), jitter 15% (100 at 5 ms or less, 0 at 200 ms).

## Limitations

- "Probe loss" is the share of failed TCP connections. It is **not** IP packet
  loss.
- On iOS, if the internet drops while the network path stays unchanged, the
  stream does not notice until the next path change, `getCurrentState()` or
  diagnostics run.
- Monitoring runs only while the app process is active. There is no background
  monitoring.
- Diagnostics use direct sockets for DNS and TCP; behind a mandatory HTTP proxy
  those checks can fail while HTTP succeeds.

## Privacy and permissions

Android declares `ACCESS_NETWORK_STATE` and `INTERNET`. iOS needs no usage
description. Traffic goes only to the probe endpoint (or one you pass).
History is stored in app-private storage excluded from backups.
Plain `http` endpoints are subject to the platform's cleartext rules.

## Example

`example/` is a dark Material 3 demo using only the public API.

```sh
cd example
flutter run
```

## License

Apache 2.0. See [LICENSE](LICENSE).
>>>>>>> 5b94255 (Intial release of Netpulse)
