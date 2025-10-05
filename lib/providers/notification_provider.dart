// notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notification_model.dart';

// Riverpod Providers
final notificationListProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList());
});

final unreadCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late FlutterLocalNotificationsPlugin _localNotifications;
  bool _isInitialized = false;

  // Get FirebaseFunctions instance
  FirebaseFunctions get _functions {
    return FirebaseFunctions.instance;
  }

  // Initialize notifications properly
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔔 Notification Service Initializing...');
    
    _localNotifications = FlutterLocalNotificationsPlugin();
    
    // Setup notification channels
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'campuscart_channel', // id
      'CampusCart Notifications', // title
      description: 'Notifications for orders, deliveries and updates', // description
      importance: Importance.high,
      playSound: true,
      showBadge: true,
      enableVibration: true,
    );

    // Create channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // iOS setup
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📱 Notification permission: ${settings.authorizationStatus}');

    // Initialize local notifications with proper settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: (id, title, body, payload) async {},
        );
    
    final InitializationSettings initializationSettings = 
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );
    
    await _localNotifications.initialize(initializationSettings);

    // Handle different message scenarios
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleBackgroundMessage(message);
    });

    // Get initial message when app is opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    _isInitialized = true;
    print('🔔 Notification Service Initialized Successfully');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 FOREGROUND MESSAGE RECEIVED');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    
    // Show local notification with proper styling
    _showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'CampusCart',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data.toString(),
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('📱 BACKGROUND MESSAGE OPENED');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    _handleNotificationNavigation(message.data);
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final orderId = data['orderId'];
    final screen = data['screen'];
    print('🧭 Navigate to: $screen, Order: $orderId, Type: $type');
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'campuscart_channel', // same as channel id
      'CampusCart Notifications',
      channelDescription: 'Notifications for orders, deliveries and updates',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      showWhen: true,
      styleInformation: DefaultStyleInformation(true, true),
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // FCM Token Management
  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('🎯 FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Get device token with better error handling
  Future<String?> _getDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 REAL FCM Token Retrieved: ${token.substring(0, 20)}...');
      } else {
        print('❌ No FCM token available');
      }
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
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

  // Remove FCM token when user logs out
  Future<void> removeFCMToken(String userId) async {
    try {
      final token = await _getDeviceToken();
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

  // Enhanced FCM token saving with verification
  Future<bool> saveFCMToken(String userId, {required String userType}) async {
    try {
      await initialize();
      final token = await _getDeviceToken();
      
      if (token != null && token.isNotEmpty) {
        print('💾 Saving FCM token for user: $userId');
        
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
        print('✅ FCM tokens saved in MULTIPLE formats for user: $userId');
        
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

  // Send notification with token checking
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
      
      // Save notification to Firestore (this will trigger your Cloud Function)
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
      
      print('✅ Notification document created for user: $userId');
      print('   Title: $title, Message: $message, Type: $type');
      print('   User has tokens: ${userTokens.isNotEmpty}');
      
      return userTokens.isNotEmpty;
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  // Real push notification method using Cloud Functions
  Future<void> _sendPushNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Call the Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('sendNotificationToUser');
      
      final result = await callable.call(<String, dynamic>{
        'userId': userId,
        'title': title,
        'message': body,
        'type': data['type'] ?? 'general',
        'additionalData': data,
      });

      print('✅ Cloud Function result: ${result.data}');
      
    } catch (e) {
      print('❌ Error calling Cloud Function: $e');
      
      // Fallback: Save to Firestore (will trigger the Cloud Function)
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': body,
        'type': data['type'] ?? 'general',
        'data': data,
        'read': false,
        'createdAt': Timestamp.now(),
      });

      // Also show local notification as final fallback
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: data.toString(),
      );
    }
  }

  // Test Cloud Function connectivity
  Future<void> testCloudFunction() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('testNotificationFunction');
      final result = await callable.call(<String, dynamic>{
        'message': 'Hello from Flutter!',
      });
      print('✅ Cloud Function test result: ${result.data}');
    } catch (e) {
      print('❌ Cloud Function test error: $e');
    }
  }

  // Test token status method
  Future<void> testTokenStatus(String uid) async {
    print('🧪 TESTING TOKEN STATUS FOR USER: $uid');
    final tokens = await getUserFCMTokens(uid);
    if (tokens.isEmpty) {
      print('❌ CRITICAL: No FCM tokens found for user $uid');
    } else {
      print('✅ SUCCESS: User $uid has ${tokens.length} FCM tokens');
    }
  }

  // Subscribe to topics for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  // Create order notification using Cloud Function
  Future<void> createOrderNotification({
    required String userId,
    required String orderId,
    required String orderNumber,
    required double amount,
  }) async {
    await _sendPushNotificationToUser(
      userId: userId,
      title: 'Order Placed Successfully! 🎉',
      body: 'Your order #$orderNumber for ₹${amount.toStringAsFixed(2)} has been confirmed',
      data: {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'amount': amount,
        'type': 'new_order',
        'screen': 'order_details',
      },
    );

    // Also save to Firestore for local notification history
    await _firestore.collection('notifications').add({
      'userId': userId,
      'userType': 'customer',
      'title': 'Order Placed Successfully! 🎉',
      'message': 'Your order #$orderNumber for ₹${amount.toStringAsFixed(2)} has been confirmed',
      'type': 'new_order',
      'data': {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'amount': amount,
        'screen': 'order_details',
      },
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Order status update notification
  Future<void> createOrderStatusNotification({
    required String userId,
    required String orderId,
    required String orderNumber,
    required String status,
    required String message,
  }) async {
    await _sendPushNotificationToUser(
      userId: userId,
      title: 'Order #$orderNumber Update',
      body: message,
      data: {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'status': status,
        'type': 'order_status_update',
        'screen': 'order_details',
      },
    );

    await _firestore.collection('notifications').add({
      'userId': userId,
      'userType': 'customer',
      'title': 'Order #$orderNumber Update',
      'message': message,
      'type': 'order_status_update',
      'data': {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'status': status,
        'screen': 'order_details',
      },
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Delivery notification
  Future<void> createDeliveryNotification({
    required String userId,
    required String orderId,
    required String orderNumber,
    required String deliveryPerson,
  }) async {
    await _sendPushNotificationToUser(
      userId: userId,
      title: 'Out for Delivery 🚚',
      body: 'Your order #$orderNumber is out for delivery by $deliveryPerson',
      data: {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'type': 'delivery',
        'screen': 'order_tracking',
      },
    );

    await _firestore.collection('notifications').add({
      'userId': userId,
      'userType': 'customer',
      'title': 'Out for Delivery 🚚',
      'message': 'Your order #$orderNumber is out for delivery by $deliveryPerson',
      'type': 'delivery',
      'data': {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'screen': 'order_tracking',
      },
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Promotion notification
  Future<void> createPromotionNotification({
    required String userId,
    required String title,
    required String message,
    required String promoCode,
  }) async {
    await _sendPushNotificationToUser(
      userId: userId,
      title: title,
      body: '$message. Use code: $promoCode',
      data: {
        'promoCode': promoCode,
        'type': 'promotion',
        'screen': 'home',
      },
    );

    await _firestore.collection('notifications').add({
      'userId': userId,
      'userType': 'customer',
      'title': title,
      'message': '$message. Use code: $promoCode',
      'type': 'promotion',
      'data': {
        'promoCode': promoCode,
        'screen': 'home',
      },
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Notification Management Methods
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'readAt': Timestamp.now(),
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> clearAllNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Get notification statistics
  Future<Map<String, int>> getNotificationStats(String userId) async {
    final totalSnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final unreadSnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    return {
      'total': totalSnapshot.docs.length,
      'unread': unreadSnapshot.docs.length,
    };
  }
}

// Authentication wrapper for FCM tokens
final authNotificationWrapperProvider = Provider<AuthNotificationWrapper>((ref) {
  return AuthNotificationWrapper(ref);
});

class AuthNotificationWrapper {
  final Ref ref;

  AuthNotificationWrapper(this.ref);

  Future<void> onUserLogin(String userId, String userType) async {
    print('🔑 Setting up notifications for user: $userId');
    
    final notificationService = ref.read(notificationServiceProvider);
    
    try {
      await notificationService.initialize();
      
      bool success = false;
      for (int i = 0; i < 3; i++) {
        success = await notificationService.saveFCMToken(userId, userType: userType);
        if (success) break;
        print('🔄 Retrying token save... Attempt ${i + 1}');
        await Future.delayed(Duration(seconds: 2));
      }
      
      if (success) {
        print('✅ Notification setup completed for user: $userId');
        final tokens = await notificationService.getUserFCMTokens(userId);
        if (tokens.isNotEmpty) {
          print('🎉 User $userId has ${tokens.length} FCM tokens - READY FOR NOTIFICATIONS!');
        }
      } else {
        print('❌ Failed to save FCM token after 3 attempts for user: $userId');
      }
    } catch (e) {
      print('❌ Error setting up notifications for user $userId: $e');
    }
  }

  Future<void> onUserLogout(String userId) async {
    print('🔑 Cleaning up notifications for user: $userId');
    
    final notificationService = ref.read(notificationServiceProvider);
    
    try {
      await notificationService.removeFCMToken(userId);
      print('✅ Notification cleanup completed for user: $userId');
    } catch (e) {
      print('❌ Error cleaning up notifications for user $userId: $e');
    }
  }
}