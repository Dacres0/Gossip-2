import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnimplementedError('Add FirebaseOptions for Web using FlutterFire.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnimplementedError('Add FirebaseOptions for Android using FlutterFire.');
      case TargetPlatform.iOS:
        throw UnimplementedError('Add FirebaseOptions for iOS using FlutterFire.');
      case TargetPlatform.macOS:
        throw UnimplementedError('Add FirebaseOptions for macOS using FlutterFire.');
      case TargetPlatform.windows:
        throw UnimplementedError('Add FirebaseOptions for Windows using FlutterFire.');
      case TargetPlatform.linux:
        throw UnimplementedError('Add FirebaseOptions for Linux using FlutterFire.');
      case TargetPlatform.fuchsia:
        throw UnimplementedError('Add FirebaseOptions for Fuchsia using FlutterFire.');
    }
  }
}
