import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, restaurantOwner, admin, restaurant }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final UserRole role;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role.index, // Store as integer index
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Convert from Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle role conversion from both integer and string formats
    UserRole role;
    if (data['role'] is int) {
      // Handle integer index
      final roleIndex = data['role'] as int;
      role = UserRole.values[roleIndex.clamp(0, UserRole.values.length - 1)];
    } else if (data['role'] is String) {
      // Handle string format (for backward compatibility)
      final roleString = data['role'] as String;
      role = UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.$roleString' || e.toString() == roleString,
        orElse: () => UserRole.user,
      );
    } else {
      role = UserRole.user;
    }

    return UserModel(
      id: data['id'] ?? doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      role: role,
      isApproved: data['isApproved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  get location => null;

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    UserRole? role,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}