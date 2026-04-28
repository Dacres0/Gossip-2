import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gossip_app/app.dart';
import 'package:gossip_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = true;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      firebaseReady = false;
    }
  }
  runApp(GossipApp(firebaseReady: firebaseReady));
}
