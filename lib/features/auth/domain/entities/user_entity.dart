import "package:equatable/equatable.dart";

class UserEntity extends Equatable {
  final int id;
  final String username;
  final String email;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
  });

  @override
  List<Object?> get props => [id, username, email];
}
