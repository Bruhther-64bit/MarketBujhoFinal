import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  bool _isLoading = false;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.signInWithEmailPassword(email, password);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential = await _authService.registerWithEmailPassword(email, password);
      
      // Save user profile
      await _firestoreService.saveUserProfile(userCredential.user!.uid, {
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential = await _authService.signInWithGoogle();
      
      // Save user profile
      await _firestoreService.saveUserProfile(userCredential.user!.uid, {
        'email': userCredential.user!.email,
        'displayName': userCredential.user!.displayName,
        'photoURL': userCredential.user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.resetPassword(email);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}