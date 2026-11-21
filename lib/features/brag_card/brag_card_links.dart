/// Play Store address of the app. One place for every card and invite surface.
///
/// The package id is `applicationId` in `android/app/build.gradle.kts`.
const sharerunPlayStorePackageId = 'com.sharerun.share_run_challenge';

/// Plain Play Store listing (no tracking parameters).
const sharerunPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=$sharerunPlayStorePackageId';

/// What the card QR holds: the Play Store address and nothing else.
///
/// The `referrer` value is only a campaign label (source / medium / campaign).
/// It is the same for every person, so the Play Console acquisition report can
/// count installs without any code or personal data on our side.
/// Never add a uid, nickname, invite code or device value here.
const bragCardInstallUrl = '$sharerunPlayStoreUrl'
    '&referrer=utm_source%3Dsharerun_card'
    '%26utm_medium%3Dqr'
    '%26utm_campaign%3Dbrag_card_v1';
