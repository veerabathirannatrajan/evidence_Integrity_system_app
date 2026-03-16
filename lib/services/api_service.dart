import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // If using Windows desktop app: http://localhost:5000
  // If using Android emulator:    http://10.0.2.2:5000
  // If using real device on WiFi: http://192.168.x.x:5000
  static const String baseUrl = 'http://localhost:5000';

  // ── Auth token ────────────────────────────────────────────────
  Future<String> _getToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('Not logged in');
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ════════════════════════════════════════════════════════════
  // USER
  // ════════════════════════════════════════════════════════════

  Future<Map> createUser(
      String uid, String name, String email, String role) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/user/create'),
      headers: _headers(token),
      body: jsonEncode(
          {'uid': uid, 'name': name, 'email': email, 'role': role}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/user/me'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }

  // ════════════════════════════════════════════════════════════
  // CASES
  // ════════════════════════════════════════════════════════════

  /// POST /api/cases
  Future<Map<String, dynamic>> createCase(
      String title,
      String description, {
        String priority     = 'medium',
        String caseType     = 'criminal',
        String location     = '',
        String caseRef      = '',
        String incidentDate = '',
      }) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/api/cases'),
        headers: _headers(token),
        body: jsonEncode({
          'title':        title.trim(),
          'description':  description.trim(),
          'priority':     priority,
          'caseType':     caseType,
          'location':     location.trim(),
          'caseRef':      caseRef.trim(),
          'incidentDate': incidentDate.isNotEmpty
              ? incidentDate
              : DateTime.now().toIso8601String(),
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode != 201) {
        throw Exception(data['message'] ?? 'Failed to create case');
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/cases
  Future<List<dynamic>> getAllCases() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/cases'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Failed to load cases: ${res.statusCode}');
    } catch (e) {
      return [];
    }
  }

  /// GET /api/cases/:id
  Future<Map<String, dynamic>> getCaseById(String id) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/cases/$id'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Case not found');
  }

  /// PATCH /api/cases/:id — update full case
  Future<Map<String, dynamic>> updateCase(
      String id, {
        String? title,
        String? description,
        String? priority,
        String? caseType,
        String? location,
        String? caseRef,
        String? incidentDate,
        String? status,
      }) async {
    final token = await _getToken();
    final Map<String, dynamic> body = {};
    if (title != null)        body['title']        = title.trim();
    if (description != null)  body['description']  = description.trim();
    if (priority != null)     body['priority']     = priority;
    if (caseType != null)     body['caseType']     = caseType;
    if (location != null)     body['location']     = location.trim();
    if (caseRef != null)      body['caseRef']      = caseRef.trim();
    if (incidentDate != null) body['incidentDate'] = incidentDate;
    if (status != null)       body['status']       = status;

    final res = await http.patch(
      Uri.parse('$baseUrl/api/cases/$id'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update case');
    }
    return data;
  }

  /// PATCH /api/cases/:id/status
  Future<Map<String, dynamic>> updateCaseStatus(
      String id, String status) async {
    final token = await _getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/api/cases/$id/status'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update status');
    }
    return data;
  }

  /// DELETE /api/cases/:id
  Future<Map<String, dynamic>> deleteCase(String id) async {
    final token = await _getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/api/cases/$id'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete case');
    }
    return data;
  }

  /// GET /api/cases/stats
  Future<Map<String, dynamic>> getCaseStats() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/cases/stats'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Failed to load case stats');
    } catch (e) {
      return {
        'total': 0,
        'byStatus':   {'open': 0, 'closed': 0, 'underReview': 0},
        'byPriority': {'low': 0, 'medium': 0, 'high': 0, 'critical': 0},
        'byType':     {'criminal': 0, 'civil': 0, 'cyber': 0,
          'fraud': 0, 'narcotics': 0, 'other': 0},
        'recentActivity': {'lastWeek': 0},
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // EVIDENCE — UPLOAD (bytes-based, works on Windows/Web/Mobile)
  // ════════════════════════════════════════════════════════════

  /// Upload evidence using raw bytes.
  /// Works on Windows desktop, Web, Android, and iOS.
  /// Never use File(path) — path is not available on Windows/Web.
  Future<Map<String, dynamic>> uploadEvidenceBytes(
      Uint8List bytes,
      String fileName,
      String caseId, {
        String description  = '',
        String evidenceType = 'document',
        String mimeType     = 'application/octet-stream',
      }) async {
    final token   = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/evidence/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // Attach file as raw bytes — no File(path) needed
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename:    fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    request.fields['caseId']       = caseId;
    request.fields['description']  = description;
    request.fields['evidenceType'] = evidenceType;

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    final data     = jsonDecode(res.body);

    if (res.statusCode != 201) {
      throw Exception(data['message'] ?? 'Upload failed');
    }
    return data;
  }

  // ════════════════════════════════════════════════════════════
  // EVIDENCE — VERIFY (bytes-based, works on Windows/Web/Mobile)
  // ════════════════════════════════════════════════════════════

  /// Verify evidence integrity using raw bytes.
  /// Works on Windows desktop, Web, Android, and iOS.
  Future<Map<String, dynamic>> verifyEvidenceBytes(
      Uint8List bytes,
      String fileName,
      String evidenceId, {
        String mimeType = 'application/octet-stream',
      }) async {
    final token   = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/evidence/verify'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename:    fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    request.fields['evidenceId'] = evidenceId;

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  // ════════════════════════════════════════════════════════════
  // EVIDENCE — READ
  // ════════════════════════════════════════════════════════════

  /// GET /api/evidence/case/:caseId
  Future<List<dynamic>> getEvidenceByCase(String caseId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/evidence/case/$caseId'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }

  /// GET /api/evidence/:id
  Future<Map<String, dynamic>> getEvidenceById(String id) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/evidence/$id'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }

  /// GET /api/evidence/public/:id — no auth, used for QR scan
  Future<Map<String, dynamic>> getEvidencePublic(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/evidence/public/$id'),
    );
    return jsonDecode(res.body);
  }

  // ════════════════════════════════════════════════════════════
  // DASHBOARD STATS & ACTIVITY
  // ════════════════════════════════════════════════════════════

  /// GET /api/evidence/stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/evidence/stats'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Failed to load stats: ${res.statusCode}');
    } catch (e) {
      return {
        'totalCases':    0,
        'totalEvidence': 0,
        'anchored':      0,
        'tampered':      0,
        'successRate':   '0',
      };
    }
  }

  /// GET /api/evidence/recent-activity
  Future<Map<String, dynamic>> getRecentActivity() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/evidence/recent-activity'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Failed to load activity');
    } catch (e) {
      return {
        'recentEvidence': [],
        'recentCustody':  [],
      };
    }
  }

  /// GET /api/evidence/recent/:limit
  Future<List<Map<String, dynamic>>> getRecentEvidence(
      {int limit = 5}) async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/evidence/recent/$limit'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      throw Exception('Failed to load recent evidence');
    } catch (e) {
      return [];
    }
  }

  /// GET /api/evidence/summary
  Future<Map<String, dynamic>> getEvidenceSummary() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/evidence/summary'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Failed to load summary');
    } catch (e) {
      return {
        'cases':  [],
        'totals': {
          'totalCases':    0,
          'totalEvidence': 0,
          'totalAnchored': 0,
          'totalTampered': 0,
          'totalPending':  0,
        },
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // CUSTODY
  // ════════════════════════════════════════════════════════════

  /// POST /api/custody/transfer
  Future<Map<String, dynamic>> transferEvidence(
      String evidenceId, String toUser, String reason) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/custody/transfer'),
      headers: _headers(token),
      body: jsonEncode({
        'evidenceId': evidenceId,
        'toUser':     toUser,
        'reason':     reason,
      }),
    );
    return jsonDecode(res.body);
  }

  /// GET /api/custody/history/:evidenceId
  Future<Map<String, dynamic>> getCustodyHistory(
      String evidenceId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/custody/history/$evidenceId'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }
}