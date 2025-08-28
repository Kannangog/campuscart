import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, restaurant, admin }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final bool isApproved;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String> savedAddresses;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.isApproved = false,
    this.phoneNumber,
    this.profileImageUrl,
    this.savedAddresses = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      isApproved: data['isApproved'] ?? false,
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      savedAddresses: List<String>.from(data['savedAddresses'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'isApproved': isApproved,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'savedAddresses': savedAddresses,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? email,
    String? name,
    UserRole? role,
    bool? isApproved,
    String? phoneNumber,
    String? profileImageUrl,
    List<String>? savedAddresses,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}