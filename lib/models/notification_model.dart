import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String userType; // 'customer' or 'restaurant'
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      userType: data['userType'] ?? 'customer',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userType': userType,
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    bool? read,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      userType: userType,
      title: title,
      body: body,
      data: data,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}