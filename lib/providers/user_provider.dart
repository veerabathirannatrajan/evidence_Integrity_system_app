// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  String? _uid;
  String? _email;
  String? _role;
  String? _name;
  bool    _loading = false;

  String? get uid     => _uid;
  String? get email   => _email;
  String? get role    => _role;
  String? get name    => _name;
  bool    get loading => _loading;

  // ── Load from backend after login ────────────────────────
  // This is the KEY fix — reads role from MongoDB via /api/user/me
  // NOT from the Firebase token directly (token needs refresh after
  // custom claim is set)
  Future<void> loadFromBackend() async {
    _loading = true;
    notifyListeners();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _loading = false;
        notifyListeners();
        return;
      }

      _uid   = firebaseUser.uid;
      _email = firebaseUser.email ?? '';

      // Force token refresh to pick up custom claims if recently set
      await firebaseUser.getIdToken(true);

      // Read IdTokenResult to get custom claims
      final tokenResult = await firebaseUser.getIdTokenResult(true);
      final claimRole   = tokenResult.claims?['role'] as String?;

      if (claimRole != null && claimRole.isNotEmpty) {
        // Custom claim present — use it
        _role = claimRole;
        _name = firebaseUser.displayName ?? _email!.split('@').first;
      } else {
        // No claim yet — fetch from backend MongoDB
        try {
          final api  = ApiService();
          final data = await api.getMe();
          _role = data['role'] as String? ?? 'police';
          _name = data['name'] as String? ?? _email!.split('@').first;
        } catch (_) {
          // Backend unavailable — default to police
          _role = 'police';
          _name = _email!.split('@').first;
        }
      }
    } catch (e) {
      debugPrint('UserProvider.loadFromBackend error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Set directly (used during registration) ───────────────
  void setUser({
    required String uid,
    required String email,
    required String role,
    String name = '',
  }) {
    _uid   = uid;
    _email = email;
    _role  = role;
    _name  = name.isNotEmpty ? name : email.split('@').first;
    notifyListeners();
  }

  // ── Clear on logout ───────────────────────────────────────
  Future<void> clear() async {
    await FirebaseAuth.instance.signOut();
    _uid   = null;
    _email = null;
    _role  = null;
    _name  = null;
    notifyListeners();
  }
}