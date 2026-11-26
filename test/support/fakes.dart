import 'dart:async';
import 'dart:io';

import 'package:netpulse/netpulse.dart';
import 'package:netpulse/src/core/network_prober.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

ConnectivityState state(
  ConnectionType type,
  InternetStatus status, [
  DateTime? at,
]) => ConnectivityState(
  connectionType: type,
  internetStatus: status,
  timestamp: at ?? DateTime.now(),
);

/// A test double for the native layer.
class FakePlatform extends NetpulsePlatform with MockPlatformInterfaceMixin {
  FakePlatform({this.directory = ''});

  final String directory;
  final StreamController<ConnectivityState> events =
      StreamController<ConnectivityState>.broadcast();
  ConnectivityState current = state(
    ConnectionType.wifi,
    InternetStatus.available,
  );

  @override
  Future<ConnectivityState> getCurrentState() async => current;

  @override
  Stream<ConnectivityState> get connectivityChanges => events.stream;

  @override
  Future<String> getStorageDirectory() async => directory;
}

/// A scripted prober, so unit tests never touch the network.
class FakeProber implements NetworkProber {
  int statusCode = 200;
  Object? headError;
  Object? resolveError;

  /// Connect results consumed in order; a null entry fails that attempt.
  /// When empty every attempt takes 20 ms.
  final List<Duration?> connects = [];
  int headCalls = 0;
  int connectCalls = 0;

  @override
  Future<List<InternetAddress>> resolve(String host, Duration timeout) async {
    final error = resolveError;
    if (error != null) throw error;
    return [InternetAddress('192.0.2.1')];
  }

  @override
  Future<Duration> connect(
    InternetAddress address,
    int port,
    Duration timeout,
  ) async {
    connectCalls++;
    if (connects.isEmpty) return const Duration(milliseconds: 20);
    final next = connects.removeAt(0);
    if (next == null) throw const SocketException('refused');
    return next;
  }

  @override
  Future<int> head(Uri uri, Duration timeout) async {
    headCalls++;
    final error = headError;
    if (error != null) throw error;
    return statusCode;
  }
}

/// Lets queued asynchronous work complete.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));
