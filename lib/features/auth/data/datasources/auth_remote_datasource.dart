// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_role.dart';
import '../models/user_model.dart';
import '../../../../core/config/app_config.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> watchCurrentUser();
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String cedula,
    required String rank,
    required String phone,
  });
  Future<void> signOut();
  Future<void> updateFcmToken(String uid, String token);
  Future<void> sendPasswordResetEmail(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  Stream<UserModel?> watchCurrentUser() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return _firestore
          .collection(AppConfig.usersCollection)
          .doc(firebaseUser.uid)
          .snapshots()
          .map((snap) {
        if (!snap.exists) return null;
        return UserModel.fromFirestore(snap);
      });
    });
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    ).timeout(const Duration(seconds: 7));
    
    final uid = credential.user!.uid;
    final doc = await _firestore
        .collection(AppConfig.usersCollection)
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 7));
        
    if (!doc.exists) {
      // Primer login: crear perfil básico en Firestore
      final newUser = UserModel(
        uid: uid,
        displayName: credential.user!.displayName ?? email.split('@').first,
        email: email,
        cedula: '',
        rank: '',
        unit: '',
        currentRole: AppRole.unknown,
        baseRole: AppRole.unknown,
        fcmTokens: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .set(newUser.toFirestore())
          .timeout(const Duration(seconds: 7));
      return newUser;
    }
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String cedula,
    required String rank,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    ).timeout(const Duration(seconds: 7));
    
    final uid = credential.user!.uid;
    final normalizedName = displayName.trim().toUpperCase();
    final newUser = UserModel(
      uid: uid,
      displayName: normalizedName,
      email: email,
      cedula: cedula,
      rank: rank,
      unit: '',
      phone: phone,
      currentRole: AppRole.unknown,
      baseRole: AppRole.unknown,
      fcmTokens: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore
        .collection(AppConfig.usersCollection)
        .doc(uid)
        .set(newUser.toFirestore())
        .timeout(const Duration(seconds: 7));
    return newUser;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection(AppConfig.usersCollection).doc(uid).update({
      'fcm_tokens': FieldValue.arrayUnion([token]),
      'updated_at': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 7));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email).timeout(const Duration(seconds: 7));
  }
}
