import "package:equatable/equatable.dart";

class UserEntity extends Equatable {
  final int id;
  final String username;
  final String email;
  final int? municipalityId;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.municipalityId,
  });

  @override
  List<Object?> get props => [id, username, email, municipalityId];
}
