import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse_connectivity_sdk/netpulse_connectivity_sdk.dart';
import 'package:netpulse_connectivity_sdk/src/core/history_store.dart';
import 'package:netpulse_connectivity_sdk/src/core/quality_calculator.dart';

import 'support/fakes.dart';

void main() {
  group('QualityCalculator', () {
    NetworkQuality score(List<int> millis, int attempted) =>
        QualityCalculator.calculate(
          samples: [for (final m in millis) Duration(milliseconds: m)],
          attempted: attempted,
          measuredAt: DateTime(2026),
        );

    test('rates fast stable samples 100', () {
      final quality = score([20, 21, 20], 3);
      expect(quality.score, 100);
      expect(quality.level, QualityLevel.excellent);
      expect(quality.reliability, 1);
    });

    test('is offline without successful samples', () {
      final quality = score([], 5);
      expect(quality.score, 0);
      expect(quality.level, QualityLevel.offline);
      expect(quality.averageLatency, isNull);
    });

    test('applies the documented weights', () {
      // Latency 525 ms scores 50, no loss scores 100, no jitter scores 100.
      expect(score([525, 525], 2).score, 75);
      // Half the samples lost removes the whole loss component.
      expect(score([20], 2).score, 65);
    });

    test('computes median', () {
      const values = [
        Duration(milliseconds: 30),
        Duration(milliseconds: 10),
        Duration(milliseconds: 20),
        Duration(milliseconds: 40),
      ];
      expect(QualityCalculator.median(values).inMilliseconds, 25);
    });
  });

  group('ConnectivityState', () {
    test('round-trips through a map', () {
      final original = ConnectivityState(
        connectionType: ConnectionType.cellular,
        internetStatus: InternetStatus.captivePortal,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
        isMetered: true,
        isVpn: false,
      );
      expect(ConnectivityState.fromMap(original.toMap()), original);
    });

    test('tolerates unrecognised values', () {
      final parsed = ConnectivityState.fromMap({'connectionType': '6g'});
      expect(parsed.connectionType, ConnectionType.unknown);
      expect(parsed.internetStatus, InternetStatus.unknown);
    });
  });

  group('HistoryStore', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('netpulse_test');
    });
    tearDown(() => directory.delete(recursive: true));

    HistoryStore store({int max = 10}) => HistoryStore(
      directory: directory.path,
      maxEntries: max,
      retention: const Duration(days: 1),
    );

    HistoryEntry entry([DateTime? at]) => HistoryEntry(
      type: HistoryEventType.connected,
      state: state(ConnectionType.wifi, InternetStatus.available, at),
    );

    test('persists across instances', () async {
      await store().add(entry());
      expect(await store().read(), hasLength(1));
    });

    test('keeps concurrent writes', () async {
      final subject = store();
      await Future.wait([for (var i = 0; i < 5; i++) subject.add(entry())]);
      expect(await store().read(), hasLength(5));
    });

    test('prunes by count and age', () async {
      final subject = store(max: 2);
      await subject.add(
        entry(DateTime.now().subtract(const Duration(days: 2))),
      );
      for (var i = 0; i < 3; i++) {
        await subject.add(entry());
      }
      expect(await subject.read(), hasLength(2));
    });

    test('recovers from a corrupt file', () async {
      final file = File('${directory.path}/${HistoryStore.fileName}');
      await file.writeAsString('{not json');
      final subject = store();
      expect(await subject.read(), isEmpty);
      await subject.add(entry());
      expect(await store().read(), hasLength(1));
    });

    test('clear removes persisted entries', () async {
      final subject = store();
      await subject.add(entry());
      await subject.clear();
      expect(await store().read(), isEmpty);
    });
  });
}
