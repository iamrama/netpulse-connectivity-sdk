import 'package:flutter/foundation.dart';

/// Machine-readable reasons for a [NetPulseException].
enum NetPulseErrorCode {
  /// An API was used before `NetPulse.initialize()` or after `dispose()`.
  notInitialized,

  /// `initialize()` was called while NetPulse was already initialized.
  alreadyInitialized,

  /// A configuration value or argument is out of range.
  invalidArgument,

  /// The current platform has no NetPulse implementation.
  unsupportedPlatform,

  /// An operating system API reported a failure.
  platformFailure,

  /// The native layer returned data that could not be understood.
  invalidResponse,

  /// Local history could not be read or written.
  storageFailure,
}

/// The single exception type thrown by the NetPulse public API.
@immutable
class NetPulseException implements Exception {
  /// Creates an exception with a [code] and a human-readable [message].
  const NetPulseException(this.code, this.message, {this.cause});

  /// Why the operation failed.
  final NetPulseErrorCode code;

  /// A description suitable for logs.
  final String message;

  /// The underlying error, when there is one.
  final Object? cause;

  @override
  String toString() =>
      'NetPulseException(${code.name}): $message'
      '${cause == null ? '' : ' [$cause]'}';
}
