// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔔 Notification Service Initializing...');
    
    try {
      await _requestPermissions();
      _configureForegroundMessages();
      _configureBackgroundMessages();
      await _getAndLogToken();
      
      _isInitialized = true;
      print('🔔 Notification Service Initialized Successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
        announcement: false, carPlay: false, criticalAlert: false, provisional: false,
      );
      print('📱 User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
    }
  }

  void _configureForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 FOREGROUND MESSAGE RECEIVED');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
    });
  }

  void _configureBackgroundMessages() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 BACKGROUND MESSAGE OPENED');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
    });
  }

  Future<void> _getAndLogToken() async {
    try {
      final token = await _messaging.getToken();
      print('🎯 CURRENT FCM TOKEN: $token');
    } catch (e) {
      print('❌ Error logging FCM token: $e');
    }
  }

  // Get user's FCM tokens from ALL possible locations
  Future<List<String>> getUserFCMTokens(String userId) async {
    try {
      final tokens = <String>[];
      print('🔍 Searching for FCM tokens for user: $userId');
      
      // Try users collection first (primary location)
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userTokens = userDoc.data()?['fcmTokens'] as List<dynamic>?;
          if (userTokens != null && userTokens.isNotEmpty) {
            tokens.addAll(userTokens.whereType<String>());
            print('📱 Found ${userTokens.length} tokens in users collection');
          }
        }
      } catch (e) {
        print('⚠️ Error reading from users collection: $e');
      }
      
      // Try user_tokens collection (secondary location)
      try {
        final userTokensDoc = await _firestore.collection('user_tokens').doc(userId).get();
        if (userTokensDoc.exists) {
          final additionalTokens = userTokensDoc.data()?['tokens'] as List<dynamic>?;
          if (additionalTokens != null) {
            for (final token in additionalTokens) {
              if (token is String && !tokens.contains(token)) {
                tokens.add(token);
              }
            }
            print('📱 Found ${additionalTokens.length} tokens in user_tokens collection');
          }
        }
      } catch (e) {
        print('⚠️ Error reading from user_tokens collection: $e');
      }
      
      // Try tokens collection (individual documents)
      try {
        final tokensQuery = await _firestore.collection('tokens')
            .where('userId', isEqualTo: userId)
            .where('active', isEqualTo: true)
            .get();
        
        if (tokensQuery.docs.isNotEmpty) {
          for (final doc in tokensQuery.docs) {
            final token = doc.data()['token'] as String?;
            if (token != null && !tokens.contains(token)) {
              tokens.add(token);
            }
          }
          print('📱 Found ${tokensQuery.docs.length} tokens in tokens collection');
        }
      } catch (e) {
        print('⚠️ Error reading from tokens collection: $e');
      }
      
      print('🎯 Total FCM tokens found for user $userId: ${tokens.length}');
      if (tokens.isNotEmpty) {
        print('   Tokens: ${tokens.map((t) => t.substring(0, 10) + '...').toList()}');
      }
      
      return tokens;
    } catch (e) {
      print('❌ Error getting FCM tokens for user $userId: $e');
      return [];
    }
  }

  // Save FCM token with better error handling and verification
  Future<bool> saveFCMToken(String userId, {required String userType}) async {
    try {
      print('💾 Saving FCM token for user: $userId');
      
      await initialize();
      final token = await _messaging.getToken();
      
      if (token != null && token.isNotEmpty) {
        // Save to multiple collections for redundancy
        final batch = _firestore.batch();
        
        // 1. Save to users collection
        final userRef = _firestore.collection('users').doc(userId);
        batch.set(userRef, {
          'fcmTokens': FieldValue.arrayUnion([token]),
          'userType': userType,
          'updatedAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
        }, SetOptions(merge: true));
        
        // 2. Save to user_tokens collection
        final userTokensRef = _firestore.collection('user_tokens').doc(userId);
        batch.set(userTokensRef, {
          'tokens': FieldValue.arrayUnion([token]),
          'userId': userId,
          'userType': userType,
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
        
        // 3. Save individual token document
        final tokenRef = _firestore.collection('tokens').doc(token);
        batch.set(tokenRef, {
          'userId': userId,
          'userType': userType,
          'token': token,
          'createdAt': Timestamp.now(),
          'active': true,
        });
        
        await batch.commit();
        print('✅ FCM tokens saved in multiple formats for user: $userId');
        
        // Verify the token was saved
        return await _verifyTokenSaved(userId, token);
      } else {
        print('❌ No FCM token available for user: $userId');
        return false;
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      return false;
    }
  }

  // Verify that the token was saved correctly
  Future<bool> _verifyTokenSaved(String userId, String expectedToken) async {
    try {
      print('🔍 Verifying token save for user: $userId');
      
      bool foundInUsers = false;
      bool foundInUserTokens = false;
      bool foundInTokens = false;
      
      // Check users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final tokens = userDoc.data()?['fcmTokens'] as List<dynamic>?;
        if (tokens != null && tokens.contains(expectedToken)) {
          foundInUsers = true;
          print('✅ Token verified in users collection');
        }
      }
      
      // Check user_tokens collection
      final userTokensDoc = await _firestore.collection('user_tokens').doc(userId).get();
      if (userTokensDoc.exists) {
        final tokens = userTokensDoc.data()?['tokens'] as List<dynamic>?;
        if (tokens != null && tokens.contains(expectedToken)) {
          foundInUserTokens = true;
          print('✅ Token verified in user_tokens collection');
        }
      }
      
      // Check tokens collection
      final tokenDoc = await _firestore.collection('tokens').doc(expectedToken).get();
      if (tokenDoc.exists) {
        foundInTokens = true;
        print('✅ Token verified in tokens collection');
      }
      
      final overallSuccess = foundInUsers || foundInUserTokens || foundInTokens;
      print('🎯 Token save verification: ${overallSuccess ? 'SUCCESS' : 'FAILED'}');
      
      return overallSuccess;
    } catch (e) {
      print('❌ Error verifying token: $e');
      return false;
    }
  }

  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('📤 Sending notification to user: $userId');
      
      final userTokens = await getUserFCMTokens(userId);
      
      if (userTokens.isEmpty) {
        print('⚠️ No FCM tokens found for user: $userId');
        print('💡 Make sure user has logged in and saveFCMToken was called');
      } else {
        print('✅ Found ${userTokens.length} FCM tokens for user: $userId');
      }
      
      // ✅ FIXED: Create only ONE notification document
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'read': false,
        'createdAt': Timestamp.now(),
        'userType': data['userType'] ?? 'customer',
        'hasTokens': userTokens.isNotEmpty,
      });
      
      print('✅ Single notification document created for user: $userId');
      print('   Title: $title, Message: $message, Type: $type');
      print('   User has tokens: ${userTokens.isNotEmpty}');
      
      return userTokens.isNotEmpty;
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  // Remove FCM token when user logs out
  Future<void> removeFCMToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        // Remove from users collection
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
        
        // Remove from user_tokens collection
        await _firestore.collection('user_tokens').doc(userId).update({
          'tokens': FieldValue.arrayRemove([token]),
        });
        
        // Deactivate in tokens collection
        await _firestore.collection('tokens').doc(token).update({
          'active': false,
          'deactivatedAt': Timestamp.now(),
        });
        
        print('✅ FCM token removed from all collections for user: $userId');
      }
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }
}