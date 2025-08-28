import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  void _initializeAuthState() {
    try {
      _auth.authStateChanges().listen(
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
      
      String verificationId = '';
      
      final completer = Completer<String>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            // Auto-verification (Android only)
            await _signInWithPhoneCredential(credential, isNewUser: isNewUser);
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(_getPhoneAuthErrorMessage(e));
          }
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          if (!completer.isCompleted) {
            completer.complete(verId);
          }
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
          if (!completer.isCompleted) {
            completer.complete(verId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      // Wait for verification ID or error
      verificationId = await completer.future;
      
      return {
        'verificationId': verificationId,
        'isNewUser': isNewUser,
        'phoneNumber': formattedPhone,
      };
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
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await _signInWithPhoneCredential(
        credential, 
        name: name, 
        role: role,
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
  }) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _handleUserCreation(
          userCredential.user!,
          name: name,
          role: role,
          autoApprove: false,
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

  // Google Sign In
  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      
      // Use Firebase Auth's built-in Google provider instead of google_sign_in package
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes if needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final UserCredential userCredential;
      
      // Use different methods for web vs mobile
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        userCredential = await _auth.signInWithProvider(googleProvider);
      }
      
      if (userCredential.user != null) {
        await _handleUserCreation(
          userCredential.user!,
          name: userCredential.user!.displayName,
          role: UserRole.user,
          profileImageUrl: userCredential.user!.photoURL,
          autoApprove: true,
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

  // Email/Password Authentication
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Sign in failed: No user returned');
      }

      state = AsyncValue.data(userCredential.user);
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getSignInErrorMessage(e);
      state = AsyncValue.error(errorMessage, StackTrace.current);
      throw Exception(errorMessage);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.user,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _handleUserCreation(
          userCredential.user!,
          name: name,
          role: role,
          autoApprove: false,
        );
        state = AsyncValue.data(userCredential.user);
      } else {
        throw Exception('Sign up failed: No user returned');
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getSignUpErrorMessage(e);
      state = AsyncValue.error(errorMessage, StackTrace.current);
      throw Exception(errorMessage);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
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

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        default:
          errorMessage = 'Password reset failed: ${e.message}';
      }
      throw Exception(errorMessage);
    }
  }

  // Check if user is demo account (hide from normal flows)
  bool isDemoAccount(String email) {
    final demoEmails = [
      'demo@example.com',
      'test@example.com',
      'admin@test.com',
      'restaurant@test.com',
    ];
    return demoEmails.contains(email.toLowerCase());
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
      default:
        return 'OTP verification failed: ${e.message}';
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
      case 'wrong-password':
        return 'Incorrect password entered.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different credential.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  String _getPhoneAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      default:
        return 'Phone authentication failed: ${e.message}';
    }
  }

  String _getGoogleSignInErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different credential.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for the provided credentials.';
      case 'invalid-credential':
        return 'Invalid Google credentials.';
      default:
        return 'Google sign-in failed: ${e.message}';
    }
  }

  String _getSignInErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-email':
        return 'Invalid email address format.';
      default:
        return 'Sign in failed: ${e.message}';
    }
  }

  String _getSignUpErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'Invalid email address format.';
      default:
        return 'Sign up failed: ${e.message}';
    }
  }

  // User creation handler
  Future<void> _handleUserCreation(
    User user, {
    String? name,
    UserRole? role,
    String? profileImageUrl,
    required bool autoApprove,
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
      } else {
        // Update existing user if needed
        final updates = <String, dynamic>{
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        if (name != null) updates['name'] = name;
        if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
        if (role != null) updates['role'] = role.toString();

        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      rethrow;
    }
  }
}