import Flutter
import UIKit
import XCTest

@testable import netpulse_connectivity_sdk

class RunnerTests: XCTestCase {

  func testCurrentStateReturnsSnapshot() {
    let plugin = NetpulsePlugin()
    let call = FlutterMethodCall(methodName: "getCurrentState", arguments: nil)
    let done = expectation(description: "result block must be called")

    plugin.handle(call) { result in
      let map = result as? [String: Any]
      XCTAssertNotNil(map?["connectionType"] as? String)
      XCTAssertNotNil(map?["internetStatus"] as? String)
      done.fulfill()
    }
    waitForExpectations(timeout: 5)
  }

  func testStorageDirectoryExists() {
    let plugin = NetpulsePlugin()
    let call = FlutterMethodCall(methodName: "getStorageDirectory", arguments: nil)
    let done = expectation(description: "result block must be called")

    plugin.handle(call) { result in
      let path = result as? String
      XCTAssertNotNil(path)
      XCTAssertTrue(FileManager.default.fileExists(atPath: path ?? ""))
      done.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testUnknownMethodIsNotImplemented() {
    let plugin = NetpulsePlugin()
    let call = FlutterMethodCall(methodName: "nope", arguments: nil)
    let done = expectation(description: "result block must be called")

    plugin.handle(call) { result in
      XCTAssertTrue((result as AnyObject) === FlutterMethodNotImplemented)
      done.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
