enum UserRole { teacher, parent, student }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role; // teacher, student, parent

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  // Convert App User -> json
  Map<String, dynamic> toJson() {
    return {'uid': uid, 'email': email, 'name': name, 'role': role.name};
  }

  // convert json -> App User
  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      uid: jsonUser['uid'],
      email: jsonUser['email'],
      name: jsonUser['name'],
      role: UserRole.values.firstWhere((e) => e.name == jsonUser['role']),
    );
  }
}
