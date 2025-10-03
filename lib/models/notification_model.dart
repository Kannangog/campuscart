// notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String userType;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  // Fixed factory method
  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Handle both 'message' and 'body' fields for backward compatibility
    final message = data['message'] as String? ?? data['body'] as String? ?? '';
    
    // Handle createdAt field - could be Timestamp or could be missing
    DateTime createdAt;
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now(); // fallback
    }

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userType: data['userType'] as String? ?? 'customer',
      title: data['title'] as String? ?? '',
      message: message,
      type: data['type'] as String? ?? 'general',
      data: Map<String, dynamic>.from(data['data'] as Map? ?? {}),
      read: data['read'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userType': userType,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? userType,
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, read: $read)';
  }
}