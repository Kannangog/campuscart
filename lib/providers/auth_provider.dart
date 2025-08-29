import 'package:campuscart/models/restaurant_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import '../models/user_model.dart';

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
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
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
        },
        onError: (error) {
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Phone Authentication with OTP
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {
    try {
      state = const AsyncValue.loading();
      
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        formattedPhone = '+1$phoneNumber'; // Default to US
      }

      // Check if user exists with this phone number
      final userQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .get();
      
      final isNewUser = userQuery.docs.isEmpty;
      
      // Use a completer to handle the verification flow
      final completer = Completer<Map<String, dynamic>>();
      
      // Set up a verification completed callback
      void verificationCompleted(PhoneAuthCredential credential) async {
        try {
          await _signInWithPhoneCredential(credential, isNewUser: isNewUser);
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

      void codeAutoRetrievalTimeout(String verificationId) {
        // This doesn't complete the completer as we want to wait for manual code entry
      }

      // Start the phone verification process
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: null,
      );

      // Wait for the verification process to complete
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
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Handle auto-verification case
      if (verificationId == 'auto-verified') {
        // User was already auto-verified, no need to verify again
        state = AsyncValue.data(_auth.currentUser);
        return;
      }
      
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Check if user exists with this phone number
      final userQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: _auth.currentUser?.phoneNumber)
          .get();
      
      final isNewUser = userQuery.docs.isEmpty;

      await _signInWithPhoneCredential(
        credential, 
        isNewUser: isNewUser,
        name: name, 
        role: role,
        restaurant: restaurant,
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
    bool isNewUser = false,
    String? name,
    UserRole? role,
    RestaurantModel? restaurant,
  }) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _handleUserCreation(
          userCredential.user!,
          name: name,
          role: role,
          autoApprove: role != null ? role != UserRole.restaurantOwner : false,
          restaurant: restaurant,
        );
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

  // Google Sign In - Enhanced with optional role parameter
  Future<void> signInWithGoogle({UserRole? role}) async {
    try {
      state = const AsyncValue.loading();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _handleUserCreation(
          userCredential.user!,
          name: userCredential.user!.displayName,
          role: role,
          profileImageUrl: userCredential.user!.photoURL,
          autoApprove: role != null ? role != UserRole.restaurantOwner : true,
        );
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
      await _googleSignIn.signOut();
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveRestaurant(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectRestaurant(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Enhanced error message handlers with more specific cases
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

  // Enhanced User creation handler with better error handling and logging
  Future<void> _handleUserCreation(
    User user, {
    String? name,
    UserRole? role,
    String? profileImageUrl,
    required bool autoApprove,
    RestaurantModel? restaurant,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Create new user document
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

        debugPrint('New user created: ${user.uid} with role: ${userModel.role}');

        // If restaurant owner, create restaurant document
        if (role == UserRole.restaurantOwner && restaurant != null) {
          final restaurantDoc = _firestore.collection('restaurants').doc();
          final restaurantWithId = restaurant.copyWith(
            id: restaurantDoc.id,
            ownerId: user.uid,
          );
          await restaurantDoc.set(restaurantWithId.toFirestore());
          debugPrint('Restaurant created for user: ${user.uid}');
        }
      } else {
        // Get existing user data to preserve role and approval status
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
        
        // Only update role if it's provided (during signup) otherwise preserve existing role
        if (role != null) {
          updates['role'] = role.index;
          debugPrint('User role updated from ${existingUser.role} to $role');
        } else {
          // Preserve existing role
          updates['role'] = existingUser.role.index;
        }
        
        // Preserve existing approval status
        updates['isApproved'] = existingUser.isApproved;

        await _firestore.collection('users').doc(user.uid).update(updates);
        debugPrint('Existing user updated: ${user.uid}');
      }
    } catch (e, stack) {
      debugPrint('Error in _handleUserCreation: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  // Additional utility methods
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

  // Password reset functionality
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
}