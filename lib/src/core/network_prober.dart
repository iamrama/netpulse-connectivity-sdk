import 'dart:async';
import 'dart:io';

/// The socket-level operations NetPulse performs. Replaceable in tests.
abstract interface class NetworkProber {
  /// Resolves [host] to its addresses.
  Future<List<InternetAddress>> resolve(String host, Duration timeout);

  /// Opens and immediately closes a TCP connection, returning its duration.
  Future<Duration> connect(InternetAddress address, int port, Duration timeout);

  /// Sends an HTTP `HEAD` request without following redirects and returns the
  /// status code once response headers arrive.
  Future<int> head(Uri uri, Duration timeout);
}

/// [NetworkProber] implemented with `dart:io`.
class IoNetworkProber implements NetworkProber {
  /// Creates a prober.
  const IoNetworkProber();

  @override
  Future<List<InternetAddress>> resolve(String host, Duration timeout) =>
      InternetAddress.lookup(host).timeout(timeout);

  @override
  Future<Duration> connect(
    InternetAddress address,
    int port,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    final socket = await Socket.connect(address, port, timeout: timeout);
    stopwatch.stop();
    socket.destroy();
    return stopwatch.elapsed;
  }

  @override
  Future<int> head(Uri uri, Duration timeout) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      Future<int> send() async {
        final request = await client.headUrl(uri);
        request.followRedirects = false;
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      }

      return await send().timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}
