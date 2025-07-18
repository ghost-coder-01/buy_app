import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MobileLoginPage extends StatefulWidget {
  const MobileLoginPage({Key? key}) : super(key: key);

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
  final mobileController = TextEditingController();
  bool _isSending = false;

  void _sendOtp() async {
    final phone = mobileController.text.trim();

    // Validate phone number format
    if (phone.isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    if (!phone.startsWith('+')) {
      _showError('Please enter phone number with country code (e.g., +91)');
      return;
    }

    if (phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    print("📱 Validating phone: $phone");
    setState(() => _isSending = true);

    try {
      // Step 1: Check if the phone number exists in Firestore
      print("🔍 Checking if user exists in Firestore...");
      final result = await FirebaseFirestore.instance
          .collection('customers')
          .where('phone', isEqualTo: phone)
          .get();

      print("📊 Firestore query result: ${result.docs.length} users found");

      if (result.docs.isEmpty) {
        _showError(
          'This phone number is not registered. Please sign up first.',
        );
        setState(() => _isSending = false);
        return;
      }

      print("✅ User found! Sending OTP...");

      // Step 2: Send OTP if user exists
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print("🎉 Auto verification completed!");
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            Navigator.pushReplacementNamed(context, '/home');
          } catch (e) {
            print("❌ Auto verification failed: $e");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print("❌ Verification failed: ${e.code} - ${e.message}");
          setState(() => _isSending = false);

          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Try again tomorrow';
              break;
            case 'invalid-app-credential':
              errorMessage =
                  'reCAPTCHA verification failed. Please refresh the page and try again.';
              break;
            case 'web-context-cancelled':
              errorMessage = 'reCAPTCHA was cancelled. Please try again.';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed';
          }
          _showError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          print("📨 OTP sent successfully! Verification ID: $verificationId");
          setState(() => _isSending = false);
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: {
              'phone': phone,
              'verificationId': verificationId,
              'resendToken': resendToken,
            },
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("⏰ Auto retrieval timeout for: $verificationId");
        },
      );
    } catch (e) {
      print("💥 Unexpected error: $e");
      setState(() => _isSending = false);
      _showError('Network error: Please check your connection');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: colorPallete.color4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your Mobile',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
              SizedBox(height: 50),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey, width: 3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorPallete.color1,
                      width: 3,
                    ),
                  ),
                  hintText: 'Mobile',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 50),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorPallete.color1, colorPallete.color2],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(320, 55),
                    shadowColor: colorPallete.color4,
                    backgroundColor: colorPallete.color4,
                  ),
                  onPressed: _isSending ? null : _sendOtp,
                  child: _isSending
                      ? CircularProgressIndicator()
                      : Text(
                          'Send OTP',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
