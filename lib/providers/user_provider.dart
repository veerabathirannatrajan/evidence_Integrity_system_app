import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String? _role;
  String? _uid;
  String? _email;
  String? _name;

  String? get role  => _role;
  String? get uid   => _uid;
  String? get email => _email;
  String? get name  => _name;

  bool get isPolice     => _role == 'police';
  bool get isForensic   => _role == 'forensic';
  bool get isProsecutor => _role == 'prosecutor';
  bool get isDefense    => _role == 'defense';
  bool get isCourt      => _role == 'court';

  // Can upload evidence: police + forensic only
  bool get canUpload    => isPolice || isForensic;
  // Can transfer custody: police + forensic only
  bool get canTransfer  => isPolice || isForensic;
  // Can create cases: police only
  bool get canCreateCase => isPolice;
  // Can view blockchain proof: prosecutor + defense + court
  bool get canViewBlockchain => isProsecutor || isDefense || isCourt;

  Future<void> loadFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _uid   = user.uid;
    _email = user.email;

    // Role comes from Firebase custom claims
    final idTokenResult = await user.getIdTokenResult(true);
    _role = idTokenResult.claims?['role'] as String?;

    notifyListeners();
  }

  void clear() {
    _role = _uid = _email = _name = null;
    notifyListeners();
  }
}