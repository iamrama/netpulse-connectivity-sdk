// Runs on a real device or emulator and exercises the native code.
//
//   cd example && flutter test integration_test
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:netpulse/netpulse.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(NetPulse.initialize);
  tearDown(NetPulse.dispose);

  testWidgets('returns a native snapshot', (tester) async {
    final state = await NetPulse.getCurrentState();
    expect(state.connectionType, isNot(ConnectionType.unknown));
  });

  testWidgets('streams an initial state', (tester) async {
    final state = await NetPulse.connectivityStream.first.timeout(
      const Duration(seconds: 15),
    );
    expect(state.connectionType, isNot(ConnectionType.unknown));
  });

  testWidgets('persists diagnostics history', (tester) async {
    await NetPulse.clearHistory();
    // Passes online or offline: failures are results, not exceptions.
    final result = await NetPulse.runDiagnostics();
    expect(result.steps, hasLength(DiagnosticTest.values.length));

    await NetPulse.dispose();
    await NetPulse.initialize();
    final history = await NetPulse.getHistory();
    expect(
      history.where((e) => e.type == HistoryEventType.diagnostics),
      isNotEmpty,
    );
  });

  testWidgets('survives repeated lifecycle changes', (tester) async {
    for (var i = 0; i < 3; i++) {
      await NetPulse.dispose();
      await NetPulse.initialize();
    }
    expect(NetPulse.isInitialized, isTrue);
  });
}
