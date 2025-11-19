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
      String formattedPhone = phoneNumber.trim();
      
      // Ensure phone number has country code
      if (!formattedPhone.startsWith('+')) {
        // Remove leading zeros (common in local phone number formats)
        formattedPhone = formattedPhone.replaceFirst(RegExp(r'^0+'), '');
        
        // Default to +970 (Palestine) or +1 (US/Canada)
        // You can change this based on your target market
        formattedPhone = '+970$formattedPhone'; // Change to your default country code
      } else {
        // If already has country code, ensure no leading zeros after the country code
        // Handle cases like +9700593202026 -> +970593202026
        if (formattedPhone.startsWith('+9700')) {
          formattedPhone = '+970' + formattedPhone.substring(5);
        } else if (formattedPhone.startsWith('+970') && formattedPhone.length > 4 && formattedPhone[4] == '0') {
          formattedPhone = '+970' + formattedPhone.substring(5);
        }
      }

      print('📱 Attempting to send OTP to: $formattedPhone');

      bool codeSent = false;
      bool errorOccurred = false;

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification completed (Android only)
          print('✅ Auto-verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
          print('❌ Error details: ${e.toString()}');
          if (e.stackTrace != null) {
            print('❌ Stack trace: ${e.stackTrace}');
          }
          
          if (!errorOccurred) {
            errorOccurred = true;
            String errorMsg = e.message ?? 'Failed to send OTP';
            
            // Provide more helpful error messages
            if (e.code == 'invalid-phone-number') {
              errorMsg = 'Invalid phone number format. Please include country code (e.g., +970XXXXXXXXX)';
            } else if (e.code == 'too-many-requests') {
              errorMsg = 'Too many requests. Please try again later.';
            } else if (e.code == 'quota-exceeded') {
              errorMsg = 'SMS quota exceeded. Please contact support.';
            } else if (e.code == 'app-not-authorized') {
              errorMsg = 'App not authorized. Please check Firebase configuration.';
            } else if (e.code == 'internal-error') {
              errorMsg = 'Internal error occurred. Please ensure:\n'
                  '1. URL scheme is registered in Info.plist\n'
                  '2. App is rebuilt after Info.plist changes\n'
                  '3. GoogleService-Info.plist is properly configured\n'
                  '4. Firebase Phone Auth is enabled in Firebase Console';
              print('❌ Firebase OTP error: ${e.message ?? "Unknown internal error"}');
            }
            
            onError(errorMsg);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ OTP code sent successfully. Verification ID received.');
          if (!codeSent && !errorOccurred) {
            codeSent = true;
            onCodeSent(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout - code was sent but not auto-retrieved
          print('⏱️ Auto-retrieval timeout. Code was sent.');
          if (!codeSent && !errorOccurred) {
            codeSent = true;
            onCodeSent(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('❌ Exception in sendOTPWithCallback: $e');
      onError('Failed to send OTP: ${e.toString()}');
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

