import 'package:equatable/equatable.dart';

/// User entity
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String? role;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.role,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, avatar, role, createdAt];
}

