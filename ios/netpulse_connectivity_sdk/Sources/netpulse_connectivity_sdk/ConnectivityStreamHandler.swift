import Flutter
import Foundation
import Network

/// Streams `NWPathMonitor` updates to Dart.
///
/// Flutter calls the stream handler on the main thread. Monitor updates arrive
/// on a private queue and are forwarded to the main thread.
final class ConnectivityStreamHandler: NSObject, FlutterStreamHandler {
  private let queue = DispatchQueue(label: "dev.netpulse.monitor")
  /// Accessed on the main thread only.
  private var monitor: NWPathMonitor?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    stop()
    // A cancelled NWPathMonitor cannot be restarted, so create a new one.
    let next = NWPathMonitor()
    monitor = next
    next.pathUpdateHandler = { [weak self, weak next] path in
      let snapshot = NetworkSnapshot.make(from: path)
      DispatchQueue.main.async {
        // Drop updates from a monitor that has since been cancelled.
        guard let self = self, let next = next, self.monitor === next else { return }
        events(snapshot)
      }
    }
    next.start(queue: queue)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stop()
    return nil
  }

  /// Cancels monitoring. Safe to call repeatedly.
  func stop() {
    monitor?.pathUpdateHandler = nil
    monitor?.cancel()
    monitor = nil
  }

  deinit {
    monitor?.cancel()
  }
}
