
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuarioActual => _auth.currentUser;

  Stream<User?> get cambiosUsuario =>
      _auth.authStateChanges();

  Future<UserCredential> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final credencial =
        await _auth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );

    await credencial.user?.updateDisplayName(nombre.trim());

    return credencial;
  }

  Future<UserCredential> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );
  }

  Future<void> recuperarContrasena(String correo) async {
    await _auth.sendPasswordResetEmail(
      email: correo.trim(),
    );
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}
