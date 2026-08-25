import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  static Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🔍 Starting Google Sign-In process');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('🔍 Google Sign-In cancelled by user');
        return AuthResult.success(
          user: null,
          message: 'Sign in was cancelled',
        );
      }

      debugPrint('🔍 Got Google user: ${googleUser?.displayName} (${googleUser?.email})');
      
      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('🔍 Got Google auth tokens: ${googleAuth.idToken?.substring(0, 20)}...');
      
      // Exchange Google token for backend token
      final backendResponse = await _exchangeTokenWithBackend(googleAuth.idToken!);
      debugPrint('🔍 Backend response: $backendResponse');
      
      if (backendResponse['success'] == true && backendResponse['data'] is Map<String, dynamic>) {
        debugPrint('🔍 Storing auth session locally');
        // Store auth session locally
        await _storeAuthSession(backendResponse['data'] as Map<String, dynamic>, googleUser);
        
        debugPrint('🔍 Google Sign-In successful');
        return AuthResult.success(
          user: _mapGoogleUserToAppUser(googleUser),
          message: 'Successfully signed in with Google',
        );
      } else {
        debugPrint('❌ Backend authentication failed: ${backendResponse['message']}');
        return AuthResult.error(
          message: (backendResponse['message'] as String?) ?? 'Authentication failed',
        );
      }
    } catch (error) {
      debugPrint('❌ Google sign in error: $error');
      return AuthResult.error(
        message: 'Failed to sign in with Google: ${error.toString()}',
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _clearAuthSession();
    } catch (error) {
      debugPrint('Sign out error: $error');
    }
  }

  static Future<bool> isSignedIn() async {
    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      return isSignedIn;
    } catch (error) {
      debugPrint('Check sign in status error: $error');
      return false;
    }
  }

  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (error) {
      debugPrint('Get current user error: $error');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _exchangeTokenWithBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {
          'success': false,
          'message': 'Invalid response format',
        };
      } else {
        return {
          'success': false,
          'message': 'Backend authentication failed: ${response.statusCode}',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<void> _storeAuthSession(
    Map<String, dynamic> backendData,
    GoogleSignInAccount googleUser,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store backend token
    await prefs.setString('auth_token', (backendData['access_token'] as String?) ?? '');
    await prefs.setString('refresh_token', (backendData['refresh_token'] as String?) ?? '');
    
    // Store user info
    final userData = backendData['user'] as Map<String, dynamic>?;
    await prefs.setString('user_id', userData?['id']?.toString() ?? '');
    await prefs.setString('user_display_name', (userData?['display_name'] as String?) ?? '');
    await prefs.setString('user_email', (userData?['email'] as String?) ?? '');
    await prefs.setString('user_avatar', (userData?['avatar_url'] as String?) ?? '');
    
    // Store token expiry
    final expiresIn = (backendData['expires_in'] as int?) ?? 3600;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await prefs.setString('token_expires_at', expiresAt.toIso8601String());
  }

  static Future<void> _clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_display_name');
    await prefs.remove('user_email');
    await prefs.remove('user_avatar');
    await prefs.remove('token_expires_at');
  }

  static Map<String, dynamic> _mapGoogleUserToAppUser(GoogleSignInAccount googleUser) {
    return {
      'id': googleUser.id,
      'display_name': googleUser.displayName ?? '',
      'email': googleUser.email,
      'avatar_url': googleUser.photoUrl,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

@immutable
class AuthResult {
  const AuthResult.success({
    required this.user,
    required this.message,
  }) : _isSuccess = true;

  const AuthResult.error({
    required this.message,
    this.user,
  }) : _isSuccess = false;

  final bool _isSuccess;
  final Map<String, dynamic>? user;
  final String message;

  bool get isSuccess => _isSuccess;
  bool get isError => !_isSuccess;
}
