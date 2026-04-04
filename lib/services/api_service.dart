import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'https://evidence-integrity-system-backend.onrender.com';
  // static const String baseUrl = 'http://localhost:5000';

  Future<String> _getToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('Not logged in');
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ══════════════════════════════════════════════════════════
  // USER
  // ══════════════════════════════════════════════════════════

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
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to get user: ${res.statusCode}');
  }

  // ══════════════════════════════════════════════════════════
  // CASES
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> createCase(
      String title,
      String description, {
        String priority = 'medium',
        String caseType = 'criminal',
        String location = '',
        String caseRef = '',
        String incidentDate = '',
      }) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/api/cases'),
        headers: _headers(token),
        body: jsonEncode({
          'title': title.trim(),
          'description': description.trim(),
          'priority': priority,
          'caseType': caseType,
          'location': location.trim(),
          'caseRef': caseRef.trim(),
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

  Future<List<dynamic>> getAllCases() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/cases'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Failed to load cases');
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getCaseById(String id) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/cases/$id'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Case not found');
  }

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
    if (title != null) body['title'] = title.trim();
    if (description != null) body['description'] = description.trim();
    if (priority != null) body['priority'] = priority;
    if (caseType != null) body['caseType'] = caseType;
    if (location != null) body['location'] = location.trim();
    if (caseRef != null) body['caseRef'] = caseRef.trim();
    if (incidentDate != null) body['incidentDate'] = incidentDate;
    if (status != null) body['status'] = status;
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
        'byStatus': {'open': 0, 'closed': 0, 'underReview': 0},
        'byPriority': {'low': 0, 'medium': 0, 'high': 0, 'critical': 0},
        'byType': {
          'criminal': 0,
          'civil': 0,
          'cyber': 0,
          'fraud': 0,
          'narcotics': 0,
          'other': 0
        },
        'recentActivity': {'lastWeek': 0},
      };
    }
  }

  // ══════════════════════════════════════════════════════════
  // EVIDENCE — UPLOAD
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> uploadEvidenceBytes(
      Uint8List bytes,
      String fileName,
      String caseId, {
        String description = '',
        String evidenceType = 'document',
        String mimeType = 'application/octet-stream',
      }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/api/evidence/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: MediaType.parse(mimeType),
    ));
    request.fields['caseId'] = caseId;
    request.fields['description'] = description;
    request.fields['evidenceType'] = evidenceType;
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) {
      throw Exception(data['message'] ?? 'Upload failed');
    }
    return data;
  }

  // ══════════════════════════════════════════════════════════
  // EVIDENCE — VERIFY
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> verifyEvidenceBytes(
      Uint8List bytes,
      String fileName,
      String evidenceId, {
        String mimeType = 'application/octet-stream',
      }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/api/evidence/verify'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: MediaType.parse(mimeType),
    ));
    request.fields['evidenceId'] = evidenceId;
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  // ══════════════════════════════════════════════════════════
  // EVIDENCE — READ
  // ══════════════════════════════════════════════════════════

  Future<List<dynamic>> getCasesWithEvidence() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/evidence/cases-with-evidence'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load cases with evidence');
  }

  Future<List<dynamic>> getEvidenceByCase(String caseId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/evidence/case/$caseId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load evidence for case');
  }

  Future<Map<String, dynamic>> getEvidenceById(String id) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/evidence/$id'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getEvidencePublic(String id) async {
    final res =
    await http.get(Uri.parse('$baseUrl/api/evidence/public/$id'));
    return jsonDecode(res.body);
  }

  // ══════════════════════════════════════════════════════════
  // DASHBOARD STATS & ACTIVITY
  // ══════════════════════════════════════════════════════════

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
        'totalCases': 0,
        'totalEvidence': 0,
        'anchored': 0,
        'tampered': 0,
        'successRate': '0',
      };
    }
  }

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
      return {'recentEvidence': [], 'recentCustody': []};
    }
  }

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
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      throw Exception('Failed to load recent evidence');
    } catch (e) {
      return [];
    }
  }

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
        'cases': [],
        'totals': {
          'totalCases': 0,
          'totalEvidence': 0,
          'totalAnchored': 0,
          'totalTampered': 0,
          'totalPending': 0,
        },
      };
    }
  }

  // ══════════════════════════════════════════════════════════
  // CUSTODY
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> transferEvidence(
      String evidenceId, String toUser, String reason) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/custody/transfer'),
      headers: _headers(token),
      body: jsonEncode({
        'evidenceId': evidenceId,
        'toUser': toUser,
        'reason': reason,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getCustodyHistory(String evidenceId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/custody/history/$evidenceId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to get custody history');
  }

  Future<Map<String, dynamic>> transferCustody(
      String evidenceId,
      String toUser,
      String reason, {
        required String toRole,
        String notes = '',
      }) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/custody/transfer'),
      headers: _headers(token),
      body: jsonEncode({
        'evidenceId': evidenceId,
        'toUser': toUser,
        'toRole': toRole,
        'reason': reason,
        'notes': notes,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Transfer failed');
  }

  Future<Map<String, dynamic>> getAllowedRoles() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/custody/allowed-roles'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {'allowedRoles': []};
    } catch (_) {
      return {'allowedRoles': []};
    }
  }

  Future<Map<String, dynamic>> getCustodyByCase(String caseId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/custody/case/$caseId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to get custody by case');
  }

  // ══════════════════════════════════════════════════════════
  // RISK INTELLIGENCE
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getRiskDashboard({
    String? riskLevel,
    String? caseId,
    bool? unreviewed,
    int limit = 50,
  }) async {
    try {
      final token = await _getToken();
      final params = <String, String>{'limit': '$limit'};
      if (riskLevel != null) params['riskLevel'] = riskLevel;
      if (caseId != null) params['caseId'] = caseId;
      if (unreviewed == true) params['reviewed'] = 'false';
      final uri = Uri.parse('$baseUrl/api/risk/dashboard')
          .replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Failed to load risk dashboard: ${res.statusCode}');
    } catch (e) {
      return {'stats': {}, 'items': [], 'raw': []};
    }
  }

  Future<Map<String, dynamic>> getRiskStats() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/risk/stats'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Failed to load risk stats: ${res.statusCode}');
    } catch (e) {
      return {
        'total': 0,
        'violations': 0,
        'high': 0,
        'suspicious': 0,
        'anomalies': 0,
        'medium': 0,
        'unreviewed': 0,
        'last24h': 0,
        'topRisky': [],
      };
    }
  }

  Future<Map<String, dynamic>> getRiskByEvidence(String evidenceId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/risk/evidence/$evidenceId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load risk for evidence');
  }

  Future<Map<String, dynamic>> reviewRiskEvent(
      String eventId, {
        String notes = '',
      }) async {
    final token = await _getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/api/risk/$eventId/review'),
      headers: _headers(token),
      body: jsonEncode({'reviewNotes': notes}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Failed to review event');
  }

  Future<Map<String, dynamic>> simulateRisk(
      String scenario, String evidenceId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/risk/simulate'),
      headers: _headers(token),
      body: jsonEncode({'scenario': scenario, 'evidenceId': evidenceId}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Simulation failed');
  }

  Future<Map<String, dynamic>> getAuditReport(String evidenceId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/risk/audit/$evidenceId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to get audit report');
  }
}