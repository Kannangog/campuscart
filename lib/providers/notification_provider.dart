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

  // Get FirebaseFunctions instance
  FirebaseFunctions get _functions {
    // Use your Firebase project region if different
    return FirebaseFunctions.instance;
    // If you need to specify a region, use:
    // return FirebaseFunctions.instanceFor(region: 'us-central1');
  }

  // Initialize notifications properly
  Future<void> initialize() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    
    // Setup notification channels like in the image
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

    print('Notification permission: ${settings.authorizationStatus}');

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
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    // Show local notification with proper styling
    _showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'CampusCart',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data.toString(),
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message opened: ${message.data}');
    // Handle navigation when user taps notification
    // You can add navigation logic here based on message.data
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

  // UPDATED: Real push notification method using Cloud Functions
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

      print('Cloud Function result: ${result.data}');
      
    } catch (e) {
      print('Error calling Cloud Function: $e');
      
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
      print('Cloud Function test result: ${result.data}');
    } catch (e) {
      print('Cloud Function test error: $e');
    }
  }

  // FCM Token Management
  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> saveFCMToken(String userId) async {
    try {
      String? token = await getFCMToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmTokenUpdatedAt': Timestamp.now(),
        });
        print('FCM Token saved for user: $userId');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // UPDATED: Create order notification using Cloud Function
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

  // UPDATED: Order status update notification
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

  // UPDATED: Delivery notification
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

  // UPDATED: Promotion notification
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