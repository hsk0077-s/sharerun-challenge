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
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return launched
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
