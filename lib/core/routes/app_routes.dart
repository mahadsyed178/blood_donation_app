class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String newPassword = '/new-password';
  static const String roleRegistration = '/role-registration';

  static const String dashboard = '/dashboard';
  static const String createRequest = '/requests/new';
  static const String locationPicker = '/location-picker';
  static const String chatThread = '/chat/:matchId';
  static const String requestDetail = '/requests/:id';
  static const String profile = '/profile';

  static String chatThreadPath(String matchId) => '/chat/$matchId';
  static String requestDetailPath(String id) => '/requests/$id';

  /// Routes reachable without a session.
  static const Set<String> public = {
    splash,
    onboarding,
    login,
    signup,
    forgotPassword,
    newPassword,
    roleRegistration,
  };
}
