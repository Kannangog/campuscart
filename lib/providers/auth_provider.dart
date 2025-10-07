// ignore_for_file: avoid_print

import 'package:campuscart/models/restaurant_model.dart';
import 'package:campuscart/models/user_model.dart';
import 'package:campuscart/providers/notification_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

// Providers
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProvider = StreamProvider.family<UserModel?, User>((ref, user) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;
  
  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initializeAuthState();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  StreamSubscription<User?>? _authSubscription;

  void _initializeAuthState() {
    try {
      _authSubscription = _auth.authStateChanges().listen(
        (user) {
          state = AsyncValue.data(user);
          if (user != null) {
            _ensureFCMTokenForUser(user);
          }
        },
        onError: (error) {
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // ✅ FIXED: Ensure FCM token exists for authenticated user
  Future<void> _ensureFCMTokenForUser(User user) async {
    try {
      print('🔐 Ensuring FCM token for authenticated user: ${user.uid}');
      
      final notificationService = ref.read(notificationServiceProvider);
      
      // Check if user already has tokens
      final existingTokens = await notificationService.getUserFCMTokens(user.uid);
      if (existingTokens.isNotEmpty) {
        print('✅ User ${user.uid} already has ${existingTokens.length} FCM tokens');
        return;
      }
      
      // Get user data to determine user type
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String userType = 'customer';
      if (userDoc.exists) {
        final userData = userDoc.data();
        userType = _getUserTypeFromData(userData);
      }
      
      print('🔄 No FCM tokens found for user ${user.uid}, saving new token...');
      await _saveFCMTokenForUser(user, userType);
      
    } catch (e) {
      print('❌ Error ensuring FCM token for user: $e');
    }
  }

  String _getUserTypeFromData(Map<String, dynamic>? userData) {
    if (userData == null) return 'customer';
    
    if (userData['userType'] != null) {
      return userData['userType'];
    }
    
    if (userData['role'] != null) {
      switch (userData['role']) {
        case 1: return 'restaurant_owner';
        case 2: return 'admin';
        default: return 'customer';
      }
    }
    
    return 'customer';
  }

  // ✅ FIXED: Save FCM token with AGGRESSIVE retry logic
  Future<void> _saveFCMTokenForUser(User user, String userType) async {
    try {
      print('🚨 AGGRESSIVE FCM TOKEN SAVE STARTED FOR: ${user.uid}');
      
      final notificationService = ref.read(notificationServiceProvider);
      
      // Ensure notification service is initialized
      await notificationService.initialize();
      await Future.delayed(const Duration(seconds: 2));
      
      // Get current FCM token
      final token = await FirebaseMessaging.instance.getToken();
      print('📱 FCM Token Retrieved: ${token != null ? '${token.substring(0, 20)}...' : 'NULL'}');
      
      if (token == null || token.isEmpty) {
        print('❌ No FCM token available from Firebase Messaging');
        return;
      }
      
      // AGGRESSIVE save with multiple attempts
      bool saveSuccess = false;
      for (int attempt = 1; attempt <= 5; attempt++) {
        print('🔄 AGGRESSIVE SAVE ATTEMPT $attempt/5 for user: ${user.uid}');
        
        try {
          saveSuccess = await _directFirestoreSave(user.uid, token, userType);
          
          if (saveSuccess) {
            print('✅ DIRECT SAVE SUCCESS on attempt $attempt');
            break;
          }
        } catch (e) {
          print('❌ Direct save error on attempt $attempt: $e');
        }
        
        if (attempt < 5) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      if (saveSuccess) {
        print('🎉 FCM TOKEN SAVE COMPLETED FOR USER: ${user.uid}');
        
        // Verify the save
        await _verifyTokenSave(user.uid, token);
      } else {
        print('💥 CRITICAL: Failed to save FCM token after 5 attempts');
        
        // Last resort: Try through notification service
        try {
          await notificationService.saveFCMToken(user.uid, userType: userType);
        } catch (e) {
          print('❌ Final fallback also failed: $e');
        }
      }
      
    } catch (e) {
      print('❌ Error in _saveFCMTokenForUser: $e');
    }
  }

  // ✅ NEW: Direct Firestore save (bypassing notification service)
  Future<bool> _directFirestoreSave(String userId, String token, String userType) async {
    try {
      print('🔥 DIRECT FIRESTORE SAVE for user: $userId');
      
      final batch = _firestore.batch();
      
      // 1. Save to users collection - CREATE IF NOT EXISTS
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(userRef, {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'userType': userType,
        'updatedAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      }, SetOptions(merge: true));
      
      // 2. Save to user_tokens collection - CREATE IF NOT EXISTS
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
      print('✅ DIRECT SAVE: Batch committed successfully');
      
      // Wait for Firestore
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    } catch (e) {
      print('❌ DIRECT SAVE FAILED: $e');
      return false;
    }
  }

  // ✅ NEW: Comprehensive token save verification
  Future<void> _verifyTokenSave(String userId, String expectedToken) async {
    try {
      print('🔍 VERIFYING TOKEN SAVE for user: $userId');
      
      final notificationService = ref.read(notificationServiceProvider);
      final tokens = await notificationService.getUserFCMTokens(userId);
      
      if (tokens.isEmpty) {
        print('❌ VERIFICATION FAILED: No tokens found after save');
        return;
      }
      
      final tokenExists = tokens.any((t) => t == expectedToken);
      
      if (tokenExists) {
        print('🎉 TOKEN VERIFICATION SUCCESS:');
        print('   User: $userId');
        print('   Token Count: ${tokens.length}');
        print('   Token: ${expectedToken.substring(0, 20)}...');
      } else {
        print('❌ VERIFICATION FAILED: Expected token not found');
        print('   Expected: ${expectedToken.substring(0, 20)}...');
        print('   Found: ${tokens.map((t) => t.substring(0, 10) + '...').toList()}');
      }
      
    } catch (e) {
      print('❌ Error during token verification: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Phone Authentication with OTP
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber, UserRole? role}) async {
    try {
      state = const AsyncValue.loading();
      
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        formattedPhone = '+1$phoneNumber';
      }

      // Check if user exists with this phone number
      final userQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .get();
      
      final isNewUser = userQuery.docs.isEmpty;
      
      final completer = Completer<Map<String, dynamic>>();
      
      void verificationCompleted(PhoneAuthCredential credential) async {
        try {
          await _signInWithPhoneCredential(
            credential, 
            isNewUser: isNewUser,
            role: isNewUser ? role : null,
          );
          if (!completer.isCompleted) {
            completer.complete({
              'verificationId': 'auto-verified',
              'isNewUser': isNewUser,
              'phoneNumber': formattedPhone,
            });
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      }

      void verificationFailed(FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(_getPhoneAuthErrorMessage(e));
        }
      }

      void codeSent(String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete({
            'verificationId': verificationId,
            'isNewUser': isNewUser,
            'phoneNumber': formattedPhone,
            'resendToken': resendToken,
          });
        }
      }

      void codeAutoRetrievalTimeout(String verificationId) {}

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: null,
      );

      return await completer.future;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> verifyOTP({
    required String verificationId,
    required String otp,
    String? name,
    UserRole? role,
    RestaurantModel? restaurant,
    bool? isNewUser,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      if (verificationId == 'auto-verified') {
        state = AsyncValue.data(_auth.currentUser);
        return;
      }
      
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      bool finalIsNewUser = isNewUser ?? true;
      if (_auth.currentUser?.phoneNumber != null) {
        final userQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: _auth.currentUser!.phoneNumber)
            .get();
        finalIsNewUser = userQuery.docs.isEmpty;
      }

      await _signInWithPhoneCredential(
        credential, 
        isNewUser: finalIsNewUser,
        name: name, 
        role: finalIsNewUser ? role : null,
        restaurant: finalIsNewUser ? restaurant : null,
      );
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getOTPVerificationErrorMessage(e);
      state = AsyncValue.error(errorMessage, StackTrace.current);
      throw Exception(errorMessage);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> _signInWithPhoneCredential(
    PhoneAuthCredential credential, {
    required bool isNewUser,
    String? name,
    UserRole? role,
    RestaurantModel? restaurant,
  }) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _handleUserCreation(
          userCredential.user!,
          isNewUser: isNewUser,
          name: name,
          role: role,
          autoApprove: (role != null) ? role != UserRole.restaurantOwner : false,
          restaurant: restaurant,
        );
        
        // ✅ FIXED: Save FCM token after successful authentication
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        String userType = 'customer';
        if (userDoc.exists) {
          final userData = userDoc.data();
          userType = _getUserTypeFromData(userData);
        }
        
        await _saveFCMTokenForUser(userCredential.user!, userType);
        
        state = AsyncValue.data(userCredential.user);
      } else {
        throw Exception('Authentication failed: No user returned');
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getAuthErrorMessage(e);
      state = AsyncValue.error(errorMessage, StackTrace.current);
      throw Exception(errorMessage);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }


  // Google Sign In
  Future<void> signInWithGoogle({UserRole? role}) async {
    try {
      state = const AsyncValue.loading();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        final bool isNewUser = !userDoc.exists;
        
        await _handleUserCreation(
          userCredential.user!,
          isNewUser: isNewUser,
          name: userCredential.user!.displayName,
          role: isNewUser ? role : null,
          profileImageUrl: userCredential.user!.photoURL,
          autoApprove: (role != null) ? role != UserRole.restaurantOwner : true,
        );
        
        // ✅ FIXED: Save FCM token after successful Google authentication
        String userType = 'customer';
        if (userDoc.exists) {
          final userData = userDoc.data();
          userType = _getUserTypeFromData(userData);
        }
        
        await _saveFCMTokenForUser(userCredential.user!, userType);
        
        state = AsyncValue.data(userCredential.user);
      } else {
        throw Exception('Google sign-in failed: No user returned');
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getGoogleSignInErrorMessage(e);
      state = AsyncValue.error(errorMessage, StackTrace.current);
      throw Exception(errorMessage);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.removeFCMToken(currentUser.uid);
      }
      
      await _googleSignIn.signOut();
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Enhanced User creation handler
  Future<void> _handleUserCreation(
    User user, {
    required bool isNewUser,
    String? name,
    UserRole? role,
    String? profileImageUrl,
    required bool autoApprove,
    RestaurantModel? restaurant,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (isNewUser && !userDoc.exists) {
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: name ?? user.displayName ?? 'User',
          phoneNumber: user.phoneNumber,
          profileImageUrl: profileImageUrl ?? user.photoURL,
          role: role ?? UserRole.user,
          isApproved: autoApprove,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(
              userModel.toFirestore(),
            );

        debugPrint('🆕 NEW USER CREATED: ${user.uid} with role: ${userModel.role}');

        if (role == UserRole.restaurantOwner && restaurant != null) {
          final restaurantDoc = _firestore.collection('restaurants').doc();
          final restaurantWithId = restaurant.copyWith(
            id: restaurantDoc.id,
            ownerId: user.uid,
          );
          await restaurantDoc.set(restaurantWithId.toFirestore());
          debugPrint('🏪 Restaurant created for new user: ${user.uid}');
        }
      } else if (userDoc.exists) {
        final existingUser = UserModel.fromFirestore(userDoc);
        
        final updates = <String, dynamic>{
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        if (name != null && name != existingUser.name) {
          updates['name'] = name;
        }
        
        if (profileImageUrl != null && profileImageUrl != existingUser.profileImageUrl) {
          updates['profileImageUrl'] = profileImageUrl;
        }
        
        updates['role'] = existingUser.role.index;
        updates['isApproved'] = existingUser.isApproved;

        await _firestore.collection('users').doc(user.uid).update(updates);
        debugPrint('🔄 EXISTING USER LOGGED IN: ${user.uid} with preserved role: ${existingUser.role}');
      } else {
        debugPrint('⚠️  Edge case: Creating user document for existing auth user');
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: name ?? user.displayName ?? 'User',
          phoneNumber: user.phoneNumber,
          profileImageUrl: profileImageUrl ?? user.photoURL,
          role: UserRole.user,
          isApproved: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(
              userModel.toFirestore(),
            );
        debugPrint('📝 Created missing user document: ${user.uid} with default role: ${userModel.role}');
      }
    } catch (e, stack) {
      debugPrint('❌ Error in _handleUserCreation: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  // Error message handlers
  String _getOTPVerificationErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'The OTP code entered is invalid.';
      case 'session-expired':
        return 'The OTP session has expired. Please request a new code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please try again.';
      case 'quota-exceeded':
        return 'Too many attempts. Please try again later.';
      default:
        return 'OTP verification failed: ${e.message ?? "Unknown error"}';
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Invalid authentication credentials.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for the provided credentials.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed: ${e.message ?? "Unknown error"}';
    }
  }

  String _getPhoneAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid. Please include country code.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'provider-already-linked':
        return 'This phone number is already linked to another account.';
      case 'captcha-check-failed':
        return 'Captcha verification failed. Please try again.';
      case 'missing-client-identifier':
        return 'Missing client identifier. Please contact support.';
      default:
        return 'Phone authentication failed: ${e.message ?? "Unknown error"}';
    }
  }

  String _getGoogleSignInErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for the provided credentials.';
      case 'invalid-credential':
        return 'Invalid Google credentials.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        return 'Google sign-in failed: ${e.message ?? "Unknown error"}';
    }
  }

  // Utility methods
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  Future<bool> checkUserExists(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getPasswordResetErrorMessage(e));
    } catch (e) {
      rethrow;
    }
  }

  String _getPasswordResetErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Password reset failed: ${e.message ?? "Unknown error"}';
    }
  }

  Future<void> setUserRole({required String userId, required UserRole role}) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role.index,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('✅ User role updated to: $role for user: $userId');
    } catch (e) {
      debugPrint('Error setting user role: $e');
      rethrow;
    }
  }

  Future<bool> hasUserRole({required String userId, required UserRole role}) async {
    try {
      final userData = await getUserData(userId);
      return userData?.role == role;
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return false;
    }
  }

  Future getCurrentGoogleUser() async {
    return _googleSignIn.currentUser;
  }

  // ✅ COMPLETED: Restaurant approval methods
  Future<void> approveRestaurant(String restaurantId) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'isApproved': true,
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('✅ Restaurant approved: $restaurantId');
    } catch (e) {
      debugPrint('❌ Error approving restaurant: $e');
      rethrow;
    }
  }

  Future<void> rejectRestaurant(String restaurantId) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'isApproved': false,
        'rejectedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('❌ Restaurant rejected: $restaurantId');
    } catch (e) {
      debugPrint('❌ Error rejecting restaurant: $e');
      rethrow;
    }
  }

  // ✅ COMPLETED: Restaurant owner approval methods
  Future<void> approveRestaurantOwner(String ownerId) async {
    try {
      await _firestore.collection('users').doc(ownerId).update({
        'isApproved': true,
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('✅ Restaurant owner approved: $ownerId');
    } catch (e) {
      debugPrint('❌ Error approving restaurant owner: $e');
      rethrow;
    }
  }

  Future<void> rejectRestaurantOwner(String ownerId) async {
    try {
      await _firestore.collection('users').doc(ownerId).update({
        'isApproved': false,
        'rejectedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('❌ Restaurant owner rejected: $ownerId');
    } catch (e) {
      debugPrint('❌ Error rejecting restaurant owner: $e');
      rethrow;
    }
  }

  // ✅ COMPLETED: User profile update method
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'name': name,
        'phoneNumber': phoneNumber,
        'updatedAt': Timestamp.now(),
      };

      if (profileImageUrl != null) {
        updates['profileImageUrl'] = profileImageUrl;
      }

      await _firestore.collection('users').doc(userId).update(updates);
      
      debugPrint('✅ User profile updated: $userId');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  // ✅ COMPLETED: Get pending restaurant owners
  Future<List<UserModel>> getPendingRestaurantOwners() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.restaurantOwner.index)
          .where('isApproved', isEqualTo: false)
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending restaurant owners: $e');
      return [];
    }
  }

  // ✅ COMPLETED: Get pending restaurants
  Future<List<RestaurantModel>> getPendingRestaurants() async {
    try {
      final query = await _firestore
          .collection('restaurants')
          .where('isApproved', isEqualTo: false)
          .get();

      return query.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending restaurants: $e');
      return [];
    }
  }

  // ✅ COMPLETED: Get user's restaurants
  Future<List<RestaurantModel>> getUserRestaurants(String userId) async {
    try {
      final query = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: userId)
          .get();

      return query.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user restaurants: $e');
      return [];
    }
  }

  // ✅ COMPLETED: Check if user has restaurant
  Future<bool> userHasRestaurant(String userId) async {
    try {
      final query = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user restaurant: $e');
      return false;
    }
  }

  // ✅ COMPLETED: Delete user account
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete user's restaurants
      final userRestaurants = await getUserRestaurants(userId);
      for (final restaurant in userRestaurants) {
        await _firestore.collection('restaurants').doc(restaurant.id).delete();
      }
      
      // Delete user's FCM tokens
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.removeFCMToken(userId);
      
      // Delete auth user
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
      }
      
      debugPrint('✅ User account deleted: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user account: $e');
      rethrow;
    }
  }

  // ✅ COMPLETED: Update user's restaurant
  Future<void> updateUserRestaurant({
    required String restaurantId,
    required RestaurantModel restaurant,
  }) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update(
        restaurant.toFirestore(),
      );
      
      debugPrint('✅ Restaurant updated: $restaurantId');
    } catch (e) {
      debugPrint('❌ Error updating restaurant: $e');
      rethrow;
    }
  }

  // ✅ COMPLETED: Create new restaurant
  Future<void> createRestaurant({
    required String userId,
    required RestaurantModel restaurant,
  }) async {
    try {
      final restaurantDoc = _firestore.collection('restaurants').doc();
      final restaurantWithId = restaurant.copyWith(
        id: restaurantDoc.id,
        ownerId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await restaurantDoc.set(restaurantWithId.toFirestore());
      
      debugPrint('✅ Restaurant created: ${restaurantDoc.id}');
    } catch (e) {
      debugPrint('❌ Error creating restaurant: $e');
      rethrow;
    }
  }

  // ✅ COMPLETED: Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final query = await _firestore.collection('users').get();
      
      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // ✅ COMPLETED: Get all restaurants (for admin)
  Future<List<RestaurantModel>> getAllRestaurants() async {
    try {
      final query = await _firestore.collection('restaurants').get();
      
      return query.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all restaurants: $e');
      return [];
    }
  }

  // ✅ COMPLETED: Toggle user approval status
  Future<void> toggleUserApproval(String userId, bool isApproved) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': isApproved,
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('✅ User approval toggled: $userId -> $isApproved');
    } catch (e) {
      debugPrint('❌ Error toggling user approval: $e');
      rethrow;
    }
  }

  // ✅ COMPLETED: Toggle restaurant approval status
  Future<void> toggleRestaurantApproval(String restaurantId, bool isApproved) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'isApproved': isApproved,
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('✅ Restaurant approval toggled: $restaurantId -> $isApproved');
    } catch (e) {
      debugPrint('❌ Error toggling restaurant approval: $e');
      rethrow;
    }
  }
}