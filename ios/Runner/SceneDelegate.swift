import Flutter
import UIKit
import NidThirdPartyLogin

class SceneDelegate: FlutterSceneDelegate {
  /// Cold start from a link: the URL comes with the connection options.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    for context in connectionOptions.urlContexts {
      ShareRunLinks.shared.receive(context.url)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts where NidOAuth.shared.handleURL(context.url) {
      return
    }
    // sharerun://shop and sharerun://run/<id> go to Dart; other links (Kakao,
    // Google sign-in) still reach the plugins through super.
    for context in URLContexts {
      ShareRunLinks.shared.receive(context.url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
