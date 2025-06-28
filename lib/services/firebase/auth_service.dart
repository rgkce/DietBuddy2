import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı durumunu dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Email ile giriş yap
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;

      if (user != null && user.emailVerified) {
        return AuthResult.success(user: user);
      } else {
        // Email doğrulanmamışsa doğrulama emaili gönder
        await user?.sendEmailVerification();
        return AuthResult.emailNotVerified(
          message: "Lütfen e-posta adresinizi doğrulayın. Doğrulama e-postası gönderildi.",
        );
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error(message: "Beklenmeyen bir hata oluştu.");
    }
  }

  // Email ile kayıt ol
  Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Email doğrulama gönder
        await user.sendEmailVerification();
        return AuthResult.success(
          user: user,
          message: "Doğrulama e-postası gönderildi.",
        );
      }
      return AuthResult.error(message: "Hesap oluşturulamadı.");
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error(message: "Beklenmeyen bir hata oluştu.");
    }
  }

  // Şifre sıfırlama emaili gönder
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(
        message: "Şifre sıfırlama e-postası gönderildi.",
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error(message: "Beklenmeyen bir hata oluştu.");
    }
  }

  // Email doğrulama gönder
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResult.success(
          message: "Doğrulama e-postası gönderildi.",
        );
      }
      return AuthResult.error(message: "Kullanıcı bulunamadı veya zaten doğrulanmış.");
    } catch (e) {
      return AuthResult.error(message: "Email doğrulama gönderilemedi.");
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Hesabı sil
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        return AuthResult.success(message: "Hesap başarıyla silindi.");
      }
      return AuthResult.error(message: "Kullanıcı bulunamadı.");
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error(message: "Hesap silinemedi.");
    }
  }

  // Firebase hata kodlarını Türkçe mesajlara çevir
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return "Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.";
      case 'wrong-password':
        return "Girdiğiniz şifre yanlış.";
      case 'invalid-email':
        return "Geçersiz e-posta adresi.";
      case 'user-disabled':
        return "Bu kullanıcı hesabı devre dışı bırakılmış.";
      case 'too-many-requests':
        return "Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.";
      case 'operation-not-allowed':
        return "Bu işlem şu anda desteklenmiyor.";
      case 'email-already-in-use':
        return "Bu e-posta adresi zaten kullanımda.";
      case 'weak-password':
        return "Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.";
      case 'invalid-credential':
        return "Geçersiz giriş bilgileri.";
      case 'account-exists-with-different-credential':
        return "Bu e-posta adresi farklı bir giriş yöntemiyle kayıtlı.";
      case 'requires-recent-login':
        return "Bu işlem için tekrar giriş yapmanız gerekiyor.";
      case 'provider-already-linked':
        return "Bu hesap zaten bağlı.";
      case 'no-such-provider':
        return "Bu giriş yöntemi bu hesapla ilişkili değil.";
      case 'invalid-user-token':
        return "Kullanıcı token'ı geçersiz.";
      case 'network-request-failed':
        return "Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.";
      case 'user-token-expired':
        return "Kullanıcı oturumu süresi dolmuş. Lütfen tekrar giriş yapın.";
      default:
        return "Bir hata oluştu. Lütfen tekrar deneyin.";
    }
  }
}

// Auth işlemlerinin sonucunu temsil eden sınıf
class AuthResult {
  final bool isSuccess;
  final String? message;
  final User? user;

  AuthResult._({
    required this.isSuccess,
    this.message,
    this.user,
  });

  // Başarılı sonuç
  factory AuthResult.success({String? message, User? user}) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      user: user,
    );
  }

  // Hata sonucu
  factory AuthResult.error({required String message}) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }

  // Email doğrulanmamış durumu
  factory AuthResult.emailNotVerified({required String message}) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }
}