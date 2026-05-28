// lib/firebase_options.dart
// ARCHIVO PLACEHOLDER — Reemplazar ejecutando:
// flutterfire configure --project=TU_PROYECTO_FIREBASE
//
// Instrucciones:
// 1. Instalar FlutterFire CLI: dart pub global activate flutterfire_cli
// 2. En la terminal del proyecto: flutterfire configure
// 3. Seleccionar Android y Web
// 4. Este archivo se reemplaza automáticamente

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS no configurado. Ejecute: flutterfire configure',
        );
      default:
        throw UnsupportedError(
          'Plataforma no soportada: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwzIpzQpi49raUBSbwM6j3H35L7kNnyRM',
    appId: '1:92615492487:android:cf3fd938cd4531e4ab8922',
    messagingSenderId: '92615492487',
    projectId: 'securpasstactical',
    databaseURL: 'https://securpasstactical-default-rtdb.firebaseio.com',
    storageBucket: 'securpasstactical.firebasestorage.app',
  );

  // ⚠️ REEMPLAZAR CON VALORES REALES DE FIREBASE CONSOLE

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAQQDuaIYUTVZ39jOiA1epngNtaYzNYmGc',
    appId: '1:92615492487:web:aa1779f777d8e2efab8922',
    messagingSenderId: '92615492487',
    projectId: 'securpasstactical',
    authDomain: 'securpasstactical.firebaseapp.com',
    databaseURL: 'https://securpasstactical-default-rtdb.firebaseio.com',
    storageBucket: 'securpasstactical.firebasestorage.app',
    measurementId: 'G-D9GL4Z52YP',
  );

}