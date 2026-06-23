import "package:equatable/equatable.dart";

class UserEntity extends Equatable {
  final int id;
  final String username;
  final String email;
  final int? municipalityId;
  final List<String> roles;
  final List<String> permissions;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.municipalityId,
    this.roles = const [],
    this.permissions = const [],
  });

  bool hasPermission(String permission) {
    final normalizedPermission = permission.trim().toLowerCase();
    return permissions.any((value) => value.trim().toLowerCase() == normalizedPermission);
  }

  @override
  List<Object?> get props => [id, username, email, municipalityId, roles, permissions];
}
