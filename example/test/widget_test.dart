import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse_connectivity_sdk/netpulse_connectivity_sdk.dart';
import 'package:netpulse_example/main.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePlatform extends NetpulsePlatform with MockPlatformInterfaceMixin {
  final _state = ConnectivityState(
    connectionType: ConnectionType.wifi,
    internetStatus: InternetStatus.available,
    timestamp: DateTime.now(),
  );

  @override
  Future<ConnectivityState> getCurrentState() async => _state;

  @override
  Stream<ConnectivityState> get connectivityChanges => Stream.value(_state);

  @override
  Future<String> getStorageDirectory() async => '';
}

void main() {
  setUp(() => NetpulsePlatform.instance = _FakePlatform());

  testWidgets('shows status and navigates between tabs', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const NetPulseExampleApp(
        config: NetPulseConfig(persistHistory: false),
        autoMeasure: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Internet Available'), findsOneWidget);

    await tester.tap(find.text('Diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('Run Diagnostics'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Wi-Fi Connected'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Monitoring Settings'), findsOneWidget);
  });
}
