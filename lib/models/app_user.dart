enum UserRole { passenger, driver }

class AppUser {
  final String uid;
  final UserRole role;
  final String displayName;

  const AppUser({
    required this.uid,
    required this.role,
    required this.displayName,
  });
}
