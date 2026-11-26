import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse_connectivity_sdk/netpulse_connectivity_sdk.dart';
import 'package:netpulse_connectivity_sdk/src/core/netpulse_client.dart';

import 'support/fakes.dart';

Matcher throwsCode(NetPulseErrorCode code) => throwsA(
  isA<NetPulseException>().having((e) => e.code, 'code', code),
);

void main() {
  const memory = NetPulseConfig(
    persistHistory: false,
    recheckInterval: Duration.zero,
  );
  late FakePlatform platform;
  late FakeProber prober;

  setUp(() {
    platform = FakePlatform();
    prober = FakeProber();
  });

  Future<NetPulseClient> create([NetPulseConfig config = memory]) =>
      NetPulseClient.create(config, platform: platform, prober: prober);

  group('NetPulse facade', () {
    setUp(() => NetpulsePlatform.instance = platform);
    tearDown(NetPulse.dispose);

    test('rejects use before initialize', () {
      expect(
        () => NetPulse.getCurrentState(),
        throwsCode(NetPulseErrorCode.notInitialized),
      );
    });

    test('rejects a second initialize', () async {
      final first = NetPulse.initialize(memory);
      await expectLater(
        NetPulse.initialize(memory),
        throwsCode(NetPulseErrorCode.alreadyInitialized),
      );
      await first;
      expect(NetPulse.isInitialized, isTrue);
    });

    test('can be disposed and initialized again', () async {
      await NetPulse.initialize(memory);
      await NetPulse.dispose();
      await NetPulse.dispose();
      expect(NetPulse.isInitialized, isFalse);
      await NetPulse.initialize(memory);
      expect(NetPulse.isInitialized, isTrue);
    });

    test('dispose during initialize leaves nothing running', () async {
      final starting = NetPulse.initialize(memory);
      await NetPulse.dispose();
      await starting;
      expect(NetPulse.isInitialized, isFalse);
      expect(platform.events.hasListener, isFalse);
    });

    test('validates configuration', () async {
      await expectLater(
        NetPulse.initialize(const NetPulseConfig(probeEndpoint: 'ftp://x')),
        throwsCode(NetPulseErrorCode.invalidArgument),
      );
      expect(NetPulse.isInitialized, isFalse);
    });
  });

  group('monitoring', () {
    test('streams distinct states and replays the latest', () async {
      final client = await create();
      final seen = <ConnectionType>[];
      client.connectivityStream.listen((s) => seen.add(s.connectionType));

      platform.events
        ..add(state(ConnectionType.wifi, InternetStatus.available))
        ..add(state(ConnectionType.wifi, InternetStatus.available))
        ..add(state(ConnectionType.cellular, InternetStatus.available));
      await settle();

      expect(seen, [ConnectionType.wifi, ConnectionType.cellular]);
      final replayed = await client.connectivityStream.first;
      expect(replayed.connectionType, ConnectionType.cellular);
      await client.dispose();
    });

    test('verifies unknown internet status with a probe', () async {
      final client = await create();
      final seen = <InternetStatus>[];
      client.connectivityStream.listen((s) => seen.add(s.internetStatus));

      platform.events.add(state(ConnectionType.wifi, InternetStatus.unknown));
      await settle();

      expect(seen, [InternetStatus.unknown, InternetStatus.available]);
      expect(prober.headCalls, 1);
      await client.dispose();
    });

    test('rechecks until the internet returns', () async {
      prober.headError = const SocketException('offline');
      final client = await create(
        memory.copyWith(recheckInterval: const Duration(milliseconds: 5)),
      );
      final seen = <InternetStatus>[];
      client.connectivityStream.listen((s) => seen.add(s.internetStatus));

      platform.events.add(state(ConnectionType.wifi, InternetStatus.unknown));
      await settle();
      prober.headError = null;
      await settle();

      expect(seen.last, InternetStatus.available);
      final history = await client.getHistory();
      expect(history.first.type, HistoryEventType.internetRestored);
      await client.dispose();
    });

    test('does not probe when verification is disabled', () async {
      final client = await create(
        memory.copyWith(verifyInternetAccess: false),
      );
      platform.events.add(state(ConnectionType.wifi, InternetStatus.unknown));
      await settle();
      expect(prober.headCalls, 0);
      await client.dispose();
    });

    test('records transitions newest first', () async {
      final client = await create();
      final start = DateTime.now().subtract(const Duration(minutes: 5));
      final states = [
        state(ConnectionType.wifi, InternetStatus.available, start),
        state(
          ConnectionType.cellular,
          InternetStatus.available,
          start.add(const Duration(seconds: 1)),
        ),
        state(
          ConnectionType.none,
          InternetStatus.unavailable,
          start.add(const Duration(seconds: 2)),
        ),
        state(
          ConnectionType.wifi,
          InternetStatus.available,
          start.add(const Duration(seconds: 3)),
        ),
      ];
      states.forEach(platform.events.add);
      await settle();

      final history = await client.getHistory();
      expect(history.map((e) => e.type), [
        HistoryEventType.connected,
        HistoryEventType.connectionLost,
        HistoryEventType.networkChanged,
        HistoryEventType.connected,
      ]);
      expect(await client.getHistory(limit: 1), hasLength(1));
      await client.clearHistory();
      expect(await client.getHistory(), isEmpty);
      await client.dispose();
    });

    test('dispose cancels the platform stream and closes ours', () async {
      final client = await create();
      final done = expectLater(client.connectivityStream, emitsDone);
      expect(platform.events.hasListener, isTrue);
      await client.dispose();
      await done;
      expect(platform.events.hasListener, isFalse);
      expect(
        () => client.getHistory(),
        throwsCode(NetPulseErrorCode.notInitialized),
      );
    });

    test('can be disabled', () async {
      final client = await create(memory.copyWith(enableMonitoring: false));
      expect(platform.events.hasListener, isFalse);
      await client.dispose();
    });
  });

  group('diagnostics', () {
    test('passes and records history', () async {
      final client = await create();
      final result = await client.runDiagnostics();
      expect(result.passed, isTrue);
      expect(result.tcpSamples, hasLength(5));
      final history = await client.getHistory();
      expect(history.single.type, HistoryEventType.diagnostics);
      expect(history.single.qualityScore, 100);
      await client.dispose();
    });

    test('shares concurrent runs', () async {
      final client = await create();
      final a = client.runDiagnostics();
      final b = client.runDiagnostics();
      expect(identical(a, b), isTrue);
      await a;
      expect(prober.connectCalls, 5);
      await client.dispose();
    });

    test('reports DNS failure without throwing', () async {
      prober
        ..resolveError = const SocketException('no such host')
        ..headError = const SocketException('no such host');
      final client = await create();
      final result = await client.runDiagnostics();
      expect(result.passed, isFalse);
      expect(
        result.step(DiagnosticTest.dnsResolution).status,
        DiagnosticStatus.failed,
      );
      expect(
        result.step(DiagnosticTest.tcpConnection).status,
        DiagnosticStatus.skipped,
      );
      final quality = await client.getNetworkQuality();
      expect(quality.level, QualityLevel.offline);
      await client.dispose();
    });

    test('counts failed samples', () async {
      const ms = Duration(milliseconds: 20);
      prober.connects.addAll([ms, null, ms, ms, ms]);
      final client = await create();
      final quality = await client.getNetworkQuality();
      expect(quality.probeLossRatio, closeTo(0.2, 1e-9));
      await client.dispose();
    });

    test('reuses a recent quality measurement', () async {
      final client = await create();
      await client.getNetworkQuality();
      await client.getNetworkQuality();
      expect(prober.connectCalls, 5);
      await client.getNetworkQuality(maxAge: Duration.zero);
      expect(prober.connectCalls, 10);
      await client.dispose();
    });

    test('discards quality when the network changes', () async {
      final client = await create();
      platform.events.add(state(ConnectionType.wifi, InternetStatus.available));
      await settle();
      await client.getNetworkQuality();
      platform.events.add(
        state(ConnectionType.cellular, InternetStatus.available),
      );
      platform.current = state(
        ConnectionType.cellular,
        InternetStatus.available,
      );
      await settle();
      await client.getNetworkQuality();
      expect(prober.connectCalls, 10);
      await client.dispose();
    });

    test('rejects an invalid endpoint', () async {
      final client = await create();
      expect(
        () => client.runDiagnostics(endpoint: Uri.parse('file:///x')),
        throwsCode(NetPulseErrorCode.invalidArgument),
      );
      await client.dispose();
    });
  });
}
