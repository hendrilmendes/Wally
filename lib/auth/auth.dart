import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        if (kDebugMode) print("Sem conexão com a internet");
        return null;
      }

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );
        if (kDebugMode) {
          print(
            'Usuário web autenticado com sucesso: ${userCredential.user?.displayName}',
          );
        }
        return userCredential.user;
      } else {
        final GoogleSignInAccount? googleSignInAccount = await _googleSignIn
            .signIn();
        if (googleSignInAccount == null) {
          if (kDebugMode) print("Login cancelado pelo usuário.");
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential authResult = await _auth.signInWithCredential(
          credential,
        );
        final User? user = authResult.user;

        if (user != null) {
          if (kDebugMode) {
            print(
              'Usuário mobile autenticado com sucesso: ${user.displayName}',
            );
          }
        } else {
          if (kDebugMode) print('Erro: Autenticação retornou usuário nulo.');
        }
        return user;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') {
        if (kDebugMode) print('Pop-up de login fechado pelo usuário.');
        return null;
      }
      if (kDebugMode) {
        print('Erro do Firebase na autenticação: ${e.code} - ${e.message}');
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) print('Erro desconhecido na autenticação: $e');
      return null;
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      if (kDebugMode) print("Erro no login anônimo: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await _auth.signOut();
      } else {
        await _googleSignIn.signOut();
        await _auth.signOut();
      }
      if (kDebugMode) print("Usuário desconectado com sucesso.");
    } catch (e) {
      if (kDebugMode) print("Erro ao desconectar usuário: $e");
    }
  }

  Future<User?> currentUser() async {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
