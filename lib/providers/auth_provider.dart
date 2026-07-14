import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart'; // AppUser của bạn
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool isLoading = false;
  String? errorMessage;
  bool rememberMe = false;
  String? savedEmail;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  User? get firebaseUser => _auth.currentUser;

  // Khôi phục phiên đăng nhập khi mở app
  Future<void> tryAutoLogin() async {
    rememberMe = await StorageService.isRememberMeEnabled();
    savedEmail = await StorageService.getSavedEmail();

    if (_auth.currentUser != null) {
      await _loadUserFromFirestore(_auth.currentUser!.uid);
    }
    notifyListeners();
  }

  // Tải thông tin user từ Firestore
  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromJson(doc.data()!);
      }
    } catch (e) {
      print("Load user error: $e");
    }
  }

  // Đăng ký
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Tạo user với Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Tạo AppUser và lưu vào Firestore
      AppUser newUser = AppUser(
        id: credential.user!.uid,
        fullName: fullName,
        email: email,
        // password: không lưu password thật vào Firestore
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toJson());

      _currentUser = newUser;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _handleFirebaseError(e);
      return false;
    } catch (e) {
      errorMessage = 'Đăng ký thất bại: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Đăng nhập
  Future<bool> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserFromFirestore(credential.user!.uid);

      if (_currentUser != null && remember) {
        await StorageService.saveSession(
          userId: _currentUser!.id,
          fullName: _currentUser!.fullName,
          email: _currentUser!.email,
          rememberMe: remember,
        );
      }
      rememberMe = remember;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _handleFirebaseError(e);
      return false;
    } catch (e) {
      errorMessage = 'Đăng nhập thất bại';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    await StorageService.clearSession();
    notifyListeners();
  }

  // Xử lý lỗi Firebase
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký';
      case 'user-not-found':
      case 'wrong-password':
        return 'Email hoặc mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      default:
        return 'Lỗi: ${e.message}';
    }
  }
}
