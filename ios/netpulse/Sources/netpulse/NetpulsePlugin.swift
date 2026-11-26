import Flutter
import Foundation
import Network

/// Registers the NetPulse channels with a Flutter engine.
public class NetpulsePlugin: NSObject, FlutterPlugin {
  private let streamHandler = ConnectivityStreamHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methods = FlutterMethodChannel(
      name: "netpulse/methods", binaryMessenger: registrar.messenger())
    let events = FlutterEventChannel(
      name: "netpulse/connectivity", binaryMessenger: registrar.messenger())
    let instance = NetpulsePlugin()
    registrar.addMethodCallDelegate(instance, channel: methods)
    events.setStreamHandler(instance.streamHandler)
    registrar.publish(instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    streamHandler.stop()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCurrentState":
      currentState(result)
    case "getStorageDirectory":
      storageDirectory(result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Reads the first path a short-lived monitor reports.
  private func currentState(_ result: @escaping FlutterResult) {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "dev.netpulse.snapshot")
    let once = Once()
    // The handler retains the monitor until the first update arrives.
    monitor.pathUpdateHandler = { path in
      guard !once.done else { return }
      once.done = true
      let snapshot = NetworkSnapshot.make(from: path)
      monitor.pathUpdateHandler = nil
      monitor.cancel()
      DispatchQueue.main.async { result(snapshot) }
    }
    monitor.start(queue: queue)
  }

  private func storageDirectory(_ result: FlutterResult) {
    do {
      var directory = try FileManager.default
        .url(
          for: .applicationSupportDirectory, in: .userDomainMask,
          appropriateFor: nil, create: true
        )
        .appendingPathComponent("netpulse", isDirectory: true)
      try FileManager.default.createDirectory(
        at: directory, withIntermediateDirectories: true)
      // History describes this device only, so keep it out of backups.
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try directory.setResourceValues(values)
      result(directory.path)
    } catch {
      result(
        FlutterError(
          code: "platformFailure", message: error.localizedDescription, details: nil))
    }
  }
}

/// A flag confined to a single serial queue.
private final class Once: @unchecked Sendable {
  var done = false
}
