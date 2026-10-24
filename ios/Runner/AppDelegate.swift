import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyA-qQCDl1affyv8CPF6RWSHHxyw32618E0")
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let registrar = self.registrar(forPlugin: "RunFinishImageShare") {
      let channel = FlutterMethodChannel(
        name: "share_run/finish_image_share",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "instagramInstalled":
          result(Self.canOpen("instagram-stories://share"))
        case "tiktokInstalled":
          result(Self.canOpen("tiktok://") || Self.canOpen("snssdk1233://"))
        case "shareInstagramStory":
          let path = call.arguments as? [String: Any]
          result(Self.shareInstagramStory(path: path?["path"] as? String))
        case "shareTikTok":
          result(false)
        case "installedTargets":
          result(Self.installedShareTargets())
        case "shareTarget":
          let args = call.arguments as? [String: Any]
          result(Self.shareTarget(id: args?["id"] as? String, path: args?["path"] as? String))
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return launched
  }

  private static func installedShareTargets() -> [String] {
    var ids: [String] = []
    if canOpen("instagram-stories://share") { ids.append("story") }
    if canOpen("instagram://app") { ids.append("feed") }
    if canOpen("tiktok://") || canOpen("snssdk1233://") { ids.append("tiktok") }
    if canOpen("fb://") { ids.append("facebook") }
    if canOpen("kakaotalk://") { ids.append("kakao") }
    if canOpen("line://") { ids.append("line") }
    if canOpen("twitter://") { ids.append("x") }
    if canOpen("whatsapp://") { ids.append("whatsapp") }
    if canOpen("tg://") { ids.append("telegram") }
    return ids
  }

  private static func shareTarget(id: String?, path: String?) -> Bool {
    if id == "story" { return shareInstagramStory(path: path) }
    return false
  }

  private static func canOpen(_ raw: String) -> Bool {
    guard let url = URL(string: raw) else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private static func shareInstagramStory(path: String?) -> Bool {
    guard let path,
          let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let url = URL(string: "instagram-stories://share"),
          UIApplication.shared.canOpenURL(url) else {
      return false
    }
    UIPasteboard.general.setItems(
      [["com.instagram.sharedSticker.backgroundImage": data]],
      options: [.expirationDate: Date().addingTimeInterval(60 * 5)]
    )
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
    return true
  }
}
