import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart'; // AppUser của bạn
import 'package:google_sign_in/google_sign_in.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _googleSignInInitialized = false;

  AppUser? _currentUser;
  bool isLoading = false;
  String? errorMessage;
  bool rememberMe = false;
  String? savedEmail;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  User? get firebaseUser => _auth.currentUser;

  bool get isPasswordAccount =>
      _auth.currentUser?.providerData.any(
            (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
          ) ??
      false;

  bool get isGoogleAccount =>
      _auth.currentUser?.providerData.any(
            (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
          ) ??
      false;

  bool get canChangePassword => isPasswordAccount;

  static const String googlePasswordManagedMessage =
      'Bạn đang đăng nhập bằng Google. Mật khẩu được quản lý bởi Google nên không thể đổi mật khẩu trong ứng dụng.';

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

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  Future<UserCredential?> _signInWithGoogleCredential() async {
    if (kIsWeb) {
      try {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          return null;
        }
        rethrow;
      }
    }

    await _ensureGoogleSignInInitialized();

    late final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Google ID token is missing.',
      );
    }

    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  // Đăng nhập bằng Google
  Future<bool> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _signInWithGoogleCredential();
      if (userCredential == null) {
        errorMessage = null;
        return false;
      }

      final user = userCredential.user;

      if (user == null) {
        errorMessage = 'Không thể đăng nhập bằng Google';
        return false;
      }

      final uid = user.uid;
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        final updatedDoc = await docRef.get();
        _currentUser = AppUser.fromJson(updatedDoc.data()!);
      } else {
        final newUserMap = {
          'uid': uid,
          'id': uid,
          'email': user.email ?? '',
          'fullName': user.displayName ?? 'Google User',
          'avatar': user.photoURL ?? '',
          'phone': '',
          'gender': '',
          'birthday': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        };
        await docRef.set(newUserMap);
        _currentUser = AppUser.fromJson(newUserMap);
      }

      await StorageService.saveSession(
        userId: _currentUser!.id,
        fullName: _currentUser!.fullName,
        email: _currentUser!.email,
        rememberMe: true,
      );
      rememberMe = true;

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _handleFirebaseError(e);
      return false;
    } catch (e) {
      errorMessage = 'Đăng nhập Google thất bại: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật thông tin profile
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String gender,
    required String birthday,
    required String avatar,
  }) async {
    if (_currentUser == null) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uid = _currentUser!.id;
      final updatedData = {
        'fullName': fullName,
        'phone': phone,
        'gender': gender,
        'birthday': birthday,
        'avatar': avatar,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).update(updatedData);

      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        phone: phone,
        gender: gender,
        birthday: birthday,
        avatar: avatar,
      );

      if (rememberMe) {
        await StorageService.saveSession(
          userId: _currentUser!.id,
          fullName: _currentUser!.fullName,
          email: _currentUser!.email,
          rememberMe: rememberMe,
        );
      }

      return true;
    } catch (e) {
      errorMessage = 'Cập nhật thông tin thất bại: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Refresh profile
  Future<void> refreshUser() async {
    if (_auth.currentUser != null) {
      await _loadUserFromFirestore(_auth.currentUser!.uid);
      notifyListeners();
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!canChangePassword) {
      return googlePasswordManagedMessage;
    }

    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return 'Người dùng chưa đăng nhập';
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleChangePasswordError(e);
    } catch (e) {
      return 'Đổi mật khẩu thất bại: $e';
    }
  }

  String _handleChangePasswordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu hiện tại không đúng';
      case 'weak-password':
        return 'Mật khẩu mới quá yếu';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại trước khi đổi mật khẩu';
      default:
        return e.message ?? 'Đổi mật khẩu thất bại';
    }
  }
}
