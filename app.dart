import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gossip_app/screens/auth_screen.dart';
import 'package:gossip_app/screens/map_screen.dart';
import 'package:gossip_app/theme/app_theme.dart';

class GossipApp extends StatelessWidget {
  const GossipApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gossip Map',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: firebaseReady ? const AuthGate() : const SetupRequiredScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const AuthScreen();
        }
        return const MapScreen();
      },
    );
  }
}

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0E16), Color(0xFF1E1F2B), Color(0xFF2B1C3B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Firebase setup required',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add your Firebase configuration using FlutterFire and provide your Mapbox access token before rebuilding the app.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
