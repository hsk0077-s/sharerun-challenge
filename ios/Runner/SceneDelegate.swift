import Flutter
import UIKit
import NidThirdPartyLogin

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts where NidOAuth.shared.handleURL(context.url) {
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
