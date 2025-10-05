// ignore_for_file: prefer_typing_uninitialized_variables, avoid_print

import 'dart:async';
import 'package:campuscart/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Constants

// Error handling utility
class FirestoreErrorHandler {
  static bool isIndexError(FirebaseException e) {
    return e.code == 'failed-precondition' && 
           e.message?.contains('index') == true;
  }
  
  static String getIndexErrorMessage(FirebaseException e) {
    final message = e.message ?? '';
    final regex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    final match = regex.firstMatch(message);
    
    return match != null 
        ? 'We\'re setting up your orders view. Please try again in a few moments.'
        : 'Database configuration in progress. Please wait a moment.';
  }
}

// Base stream provider with error handling and index fallback
Stream<List<OrderModel>> _createOrderStreamWithFallback(
  Query query, {
  required void Function() onIndexBuilding,
  required void Function() onIndexBuilt,
  required Ref ref,
}) {
  final streamController = StreamController<List<OrderModel>>();
  bool hasShownIndexError = false;
  bool isIndexBuilding = false;
  Timer? retryTimer;

  final subscription = query.snapshots().handleError((error, stackTrace) {
    if (error is FirebaseException && FirestoreErrorHandler.isIndexError(error)) {
      if (!hasShownIndexError) {
        hasShownIndexError = true;
        isIndexBuilding = true;
        onIndexBuilding();
        
        // Use fallback query when index is being built
        query.get().then((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          streamController.add(orders);
          
          // Set up automatic retry with the original query
          retryTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
            query.snapshots().first.then((snapshot) {
              timer.cancel();
              isIndexBuilding = false;
              hasShownIndexError = false;
              onIndexBuilt();
              
              final orders = snapshot.docs
                  .map((doc) => OrderModel.fromFirestore(doc))
                  .toList();
              streamController.add(orders);
            }).catchError((_) {
              // Continue retrying if still failing
            });
          });
        }).catchError((fallbackError) {
          streamController.addError(fallbackError, stackTrace);
        });
      }
    } else {
      streamController.addError(error, stackTrace);
    }
  }).listen((snapshot) {
    if (isIndexBuilding) {
      isIndexBuilding = false;
      hasShownIndexError = false;
      retryTimer?.cancel();
      onIndexBuilt();
    }
    
    final orders = snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();
    streamController.add(orders);
  });

  ref.onDispose(() {
    subscription.cancel();
    retryTimer?.cancel();
    streamController.close();
  });

  return streamController.stream;
}

// Stream Providers
final userOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: userId);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for user orders'),
    onIndexBuilt: () => print('Index built for user orders'),
    ref: ref,
  );
});

final restaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for restaurant orders'),
    onIndexBuilt: () => print('Index built for restaurant orders'),
    ref: ref,
  );
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final query = FirebaseFirestore.instance.collection('orders');
  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for all orders'),
    onIndexBuilt: () => print('Index built for all orders'),
    ref: ref,
  );
});

final orderProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
});