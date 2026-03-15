import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // ← Replace with your backend IP when testing on Android device
  // If using emulator: http://10.0.2.2:5000
  // If using real device on same WiFi: http://192.168.x.x:5000
  static const String baseUrl = 'http://10.0.2.2:5000';

  // Gets fresh Firebase token for every request
  Future<String> _getToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('Not logged in');
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ── User ────────────────────────────────────────────

  Future<Map> createUser(String uid, String name, String email, String role) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/user/create'),
      headers: _headers(token),
      body: jsonEncode({'uid': uid, 'name': name, 'email': email, 'role': role}),
    );
    return jsonDecode(res.body);
  }

  // ── Cases ───────────────────────────────────────────

  Future<Map> createCase(String title, String description) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/cases'),
      headers: _headers(token),
      body: jsonEncode({'title': title, 'description': description}),
    );
    return jsonDecode(res.body);
  }

  Future<List> getAllCases() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/cases'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }

  // ── Evidence ─────────────────────────────────────────

  Future<Map> uploadEvidence(File file, String caseId) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/evidence/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['caseId'] = caseId;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  Future<Map> verifyEvidence(File file, String evidenceId) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/evidence/verify'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['evidenceId'] = evidenceId;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  Future<List> getEvidenceByCase(String caseId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/evidence/case/$caseId'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }

  // ── Custody ──────────────────────────────────────────

  Future<Map> transferEvidence(String evidenceId, String toUser, String reason) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/custody/transfer'),
      headers: _headers(token),
      body: jsonEncode({'evidenceId': evidenceId, 'toUser': toUser, 'reason': reason}),
    );
    return jsonDecode(res.body);
  }

  Future<Map> getCustodyHistory(String evidenceId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/custody/history/$evidenceId'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }
}