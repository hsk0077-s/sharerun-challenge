class LocalAuthSession {
  const LocalAuthSession({
    required this.uid,
    required this.isGuest,
  });

  final String uid;
  final bool isGuest;
}
