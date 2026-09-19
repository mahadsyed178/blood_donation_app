/// What the first signup step collects, carried to the role step which adds
/// the role-specific fields and makes the actual `/signup` call.
class SignupDraft {
  final String fullName;
  final String email;
  final String password;

  const SignupDraft({
    required this.fullName,
    required this.email,
    required this.password,
  });
}
