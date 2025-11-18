import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send OTP to phone number
  Future<String> sendOTP(String phoneNumber) async {
    try {
      // Format phone number with country code (e.g., +1234567890)
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        // If no country code, assume it needs one
        // You might want to add country code selection in UI
        formattedPhone = '+1$formattedPhone'; // Default to +1, adjust as needed
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification completed (Android only)
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception(e.message ?? 'Failed to send OTP');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Code sent successfully, verificationId will be stored
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );

      // Return verification ID - we'll need to store this temporarily
      // For now, we'll use a different approach with a callback
      return '';
    } catch (e) {
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  // Send OTP with callback to get verification ID
  Future<void> sendOTPWithCallback(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
    Function(String error) onError,
  ) async {
    try {
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+1$formattedPhone';
      }

      bool codeSent = false;
      bool errorOccurred = false;

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification completed (Android only)
          // This won't be called if code is sent successfully
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!errorOccurred) {
            errorOccurred = true;
            onError(e.message ?? 'Failed to send OTP');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!codeSent && !errorOccurred) {
            codeSent = true;
            onCodeSent(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout - code was sent but not auto-retrieved
          if (!codeSent && !errorOccurred) {
            codeSent = true;
            onCodeSent(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verify OTP code
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      throw Exception('Invalid OTP code: ${e.toString()}');
    }
  }

  // Get current user's ID token
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // Get current user's phone number
  String? getCurrentUserPhone() {
    return _auth.currentUser?.phoneNumber;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

