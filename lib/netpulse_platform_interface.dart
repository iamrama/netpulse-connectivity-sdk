import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'netpulse_method_channel.dart';
import 'src/models/connectivity_state.dart';

/// The contract every NetPulse platform implementation fulfils.
///
/// Implementations expose only what requires operating system APIs. All other
/// behaviour (verification, diagnostics, scoring, history) lives in Dart.
abstract class NetpulsePlatform extends PlatformInterface {
  /// Creates a platform implementation.
  NetpulsePlatform() : super(token: _token);

  static final Object _token = Object();

  static NetpulsePlatform _instance = MethodChannelNetpulse();

  /// The active implementation. Defaults to [MethodChannelNetpulse].
  static NetpulsePlatform get instance => _instance;

  /// Replaces the active implementation, for example with a test double.
  static set instance(NetpulsePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns a snapshot of the operating system's current network state.
  Future<ConnectivityState> getCurrentState() {
    throw UnimplementedError('getCurrentState() has not been implemented.');
  }

  /// Emits the current state when listened to, then every change.
  ///
  /// Cancelling the subscription stops native monitoring.
  Stream<ConnectivityState> get connectivityChanges {
    throw UnimplementedError('connectivityChanges has not been implemented.');
  }

  /// Returns an app-private directory in which NetPulse may store history.
  Future<String> getStorageDirectory() {
    throw UnimplementedError('getStorageDirectory() has not been implemented.');
  }
}
