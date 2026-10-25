import Flutter
import Foundation
import WatchConnectivity

/// iOS <-> watchOS `WatchConnectivity` bridge (`MethodChannel("share_run/watch_bridge")`).
/// Supports:
/// - `syncCompanionAuth`: sends refreshToken + nickname to paired Apple Watch
/// - `sendRankAlert`: pushes real-time tournament rank (`rank`, `gapPeople`) to Apple Watch HUD
/// - `isWatchPaired`: checks if an Apple Watch is paired & reachable
final class WatchBridgePlugin: NSObject, WCSessionDelegate {
  private var channel: FlutterMethodChannel?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = WatchBridgePlugin()
    let methodChannel = FlutterMethodChannel(
      name: "share_run/watch_bridge",
      binaryMessenger: registrar.messenger()
    )
    instance.channel = methodChannel
    methodChannel.setMethodCallHandler(instance.handle)
    if WCSession.isSupported() {
      let session = WCSession.default
      session.delegate = instance
      session.activate()
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard WCSession.isSupported() else {
      result(false)
      return
    }
    let session = WCSession.default
    switch call.method {
    case "isWatchPaired":
      result([
        "paired": session.isPaired,
        "watchAppInstalled": session.isWatchAppInstalled,
        "reachable": session.isReachable
      ])
    case "syncCompanionAuth":
      guard let args = call.arguments as? [String: Any],
            let refreshToken = args["refreshToken"] as? String else {
        result(false)
        return
      }
      let payload: [String: Any] = [
        "type": "companion_auth",
        "refreshToken": refreshToken,
        "nickname": (args["nickname"] as? String) ?? ""
      ]
      if session.isReachable {
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
      } else {
        session.transferUserInfo(payload)
      }
      result(true)
    case "sendRankAlert":
      guard let args = call.arguments as? [String: Any],
            let rank = args["rank"] as? Int else {
        result(false)
        return
      }
      let payload: [String: Any] = [
        "type": "rank_alert",
        "rank": rank,
        "gapPeople": (args["gapPeople"] as? Int) ?? 0
      ]
      if session.isReachable {
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        result(true)
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {}

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("onWatchUserInfo", arguments: userInfo)
    }
  }
}
