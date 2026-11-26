import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'netpulse_platform_interface.dart';
import 'src/errors/netpulse_exception.dart';
import 'src/models/connectivity_state.dart';

/// The default [NetpulsePlatform], backed by Flutter platform channels.
class MethodChannelNetpulse extends NetpulsePlatform {
  /// Channel used for one-shot native calls.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('netpulse/methods');

  /// Channel used for the native connectivity event stream.
  @visibleForTesting
  final EventChannel eventChannel = const EventChannel('netpulse/connectivity');

  Stream<ConnectivityState>? _changes;

  @override
  Future<ConnectivityState> getCurrentState() async {
    final map = await _invoke<Map<Object?, Object?>>('getCurrentState');
    return ConnectivityState.fromMap(map);
  }

  @override
  Future<String> getStorageDirectory() =>
      _invoke<String>('getStorageDirectory');

  @override
  Stream<ConnectivityState> get connectivityChanges {
    return _changes ??= eventChannel.receiveBroadcastStream().transform(
      StreamTransformer<Object?, ConnectivityState>.fromHandlers(
        handleData: (event, sink) {
          if (event is Map<Object?, Object?>) {
            sink.add(ConnectivityState.fromMap(event));
          } else {
            sink.addError(
              const NetPulseException(
                NetPulseErrorCode.invalidResponse,
                'The platform sent a malformed connectivity event.',
              ),
            );
          }
        },
        handleError: (error, stackTrace, sink) {
          sink.addError(_mapError(error), stackTrace);
        },
      ),
    );
  }

  Future<T> _invoke<T extends Object>(String method) async {
    final T? result;
    try {
      result = await methodChannel.invokeMethod<T>(method);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_mapError(error), stackTrace);
    }
    if (result == null) {
      throw NetPulseException(
        NetPulseErrorCode.invalidResponse,
        'The platform returned no data for "$method".',
      );
    }
    return result;
  }

  NetPulseException _mapError(Object error) {
    if (error is NetPulseException) return error;
    if (error is MissingPluginException) {
      return NetPulseException(
        NetPulseErrorCode.unsupportedPlatform,
        'NetPulse supports Android and iOS only.',
        cause: error,
      );
    }
    return NetPulseException(
      NetPulseErrorCode.platformFailure,
      error is PlatformException
          ? error.message ?? error.code
          : 'The platform call failed.',
      cause: error,
    );
  }
}
