import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse_connectivity_sdk/netpulse_connectivity_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelNetpulse();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void handle(Future<Object?> Function(MethodCall call)? handler) {
    messenger.setMockMethodCallHandler(platform.methodChannel, handler);
  }

  tearDown(() => handle(null));

  test('parses the current state', () async {
    handle(
      (call) async => <String, Object?>{
        'connectionType': 'wifi',
        'internetStatus': 'available',
        'timestamp': 5,
      },
    );
    final state = await platform.getCurrentState();
    expect(state.connectionType, ConnectionType.wifi);
    expect(state.hasInternet, isTrue);
  });

  test('maps platform errors', () async {
    handle((call) async => throw PlatformException(code: 'x', message: 'bad'));
    await expectLater(
      platform.getCurrentState(),
      throwsA(
        isA<NetPulseException>().having(
          (e) => e.code,
          'code',
          NetPulseErrorCode.platformFailure,
        ),
      ),
    );
  });

  test('reports an unsupported platform', () async {
    await expectLater(
      platform.getStorageDirectory(),
      throwsA(
        isA<NetPulseException>().having(
          (e) => e.code,
          'code',
          NetPulseErrorCode.unsupportedPlatform,
        ),
      ),
    );
  });

  test('rejects an empty response', () async {
    handle((call) async => null);
    await expectLater(
      platform.getCurrentState(),
      throwsA(isA<NetPulseException>()),
    );
  });
}
