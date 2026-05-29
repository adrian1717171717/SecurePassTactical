// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routing/route_names.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';

// ── DataSource Provider ──────────────────────────────────
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

// ── Stream del usuario actual (con perfil Firestore en tiempo real) ─
final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRemoteDataSourceProvider).watchCurrentUser();
});

// ── Estado de autenticación simplificado ─────────────────
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull != null;
});

// ── Acción: Login ─────────────────────────────────────────
final signInProvider = Provider<Future<void> Function(String, String)>((ref) {
  return (email, password) async {
    await ref
        .read(authRemoteDataSourceProvider)
        .signInWithEmailAndPassword(email, password);
  };
});

// ── Acción: Registro ──────────────────────────────────────
final signUpProvider = Provider<
    Future<void> Function({
  required String email,
  required String password,
  required String displayName,
  required String cedula,
  required String rank,
  required String phone,
  String unit,
  String? yearLevel,
})>((ref) {
  return ({
    required email,
    required password,
    required displayName,
    required cedula,
    required rank,
    required phone,
    String unit = '',
    String? yearLevel,
  }) async {
    await ref.read(authRemoteDataSourceProvider).signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
          cedula: cedula,
          rank: rank,
          phone: phone,
          unit: unit,
          yearLevel: yearLevel,
        );
  };
});

// ── Acción: Recuperación de contraseña ────────────────────
final recoverPasswordProvider = Provider<Future<void> Function(String)>((ref) {
  return (email) async {
    await ref.read(authRemoteDataSourceProvider).sendPasswordResetEmail(email);
  };
});

// ── Acción: Logout ────────────────────────────────────────
final signOutProvider = Provider<Future<void> Function(BuildContext)>((ref) {
  return (context) async {
    // 1. Redireccionar de inmediato a la pantalla de login para desmontar
    // los dashboards y gatillar la cancelación automática de los streams.
    context.go(RouteNames.login);

    // 2. Pausar brevemente para permitir la transición y desmonte seguro
    await Future.delayed(const Duration(milliseconds: 150));

    // 3. Invalidar el stream del usuario en Riverpod para forzar reinicio del estado
    ref.invalidate(currentUserProvider);

    // 4. Firmar la salida en Firebase Auth
    await ref.read(authRemoteDataSourceProvider).signOut();
  };
});
