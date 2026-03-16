// verify_evidence_screen.dart - Re-upload file to check tamper
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class VerifyEvidenceScreen extends StatefulWidget {
  final String? evidenceId;
  const VerifyEvidenceScreen({super.key, this.evidenceId});
  @override
  State<VerifyEvidenceScreen> createState() => _VerifyEvidenceScreenState();
}

class _VerifyEvidenceScreenState extends State<VerifyEvidenceScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _idCtrl = TextEditingController();
  PlatformFile? _file;
  bool _verifying = false;
  Map<String, dynamic>? _result;
  String? _error;
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _opacity = _ctrl.drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
    if (widget.evidenceId != null) _idCtrl.text = widget.evidenceId!;
  }

  @override
  void dispose() { _ctrl.dispose(); _idCtrl.dispose(); super.dispose(); }

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.any, withData: true, allowMultiple: false);
    if (r != null && r.files.isNotEmpty) setState(() { _file = r.files.first; _result = null; _error = null; });
  }

  Future<void> _verify() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) { setState(() => _error = 'Enter the Evidence ID'); return; }
    if (_file == null) { setState(() => _error = 'Select the file to verify'); return; }
    final bytes = _file!.bytes;
    if (bytes == null) { setState(() => _error = 'Could not read file'); return; }
    setState(() { _verifying = true; _error = null; _result = null; });
    try {
      final res = await _api.verifyEvidenceBytes(bytes, _file!.name, id, mimeType: _mime(_file!.extension ?? ''));
      if (mounted) setState(() { _result = res; _verifying = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Verification failed: $e'; _verifying = false; });
    }
  }

  String _mime(String e) { switch(e.toLowerCase()) { case 'jpg': case 'jpeg': return 'image/jpeg'; case 'png': return 'image/png'; case 'pdf': return 'application/pdf'; case 'mp4': return 'video/mp4'; case 'mp3': return 'audio/mpeg'; default: return 'application/octet-stream'; } }
  String _sz(int b) { if(b<1024) return '$b B'; if(b<1048576) return '${(b/1024).toStringAsFixed(1)} KB'; return '${(b/1048576).toStringAsFixed(1)} MB'; }
  String _sh(String h) { if(h.length<=20) return h; return '\${h.substring(0,10)}...\${h.substring(h.length-8)}'; }
  void _copy(String t, String l) { Clipboard.setData(ClipboardData(text: t)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$l copied'), backgroundColor: const Color(0xFF059669), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final C = _C(isDark);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.card, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: C.txtPrimary, size: 20), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.verified_outlined, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          Text('Verify Evidence Integrity', style: TextStyle(color: C.txtPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: C.border, height: 1)),
      ),
      body: FadeTransition(
        opacity: _opacity,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Left: form
          Expanded(flex: 3, child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // How it works
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(isDark ? 0.08 : 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2))),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Re-upload the original file. The system computes its SHA-256 hash and compares it with the hash stored in MongoDB and anchored on the Polygon blockchain. Even a single-bit change will be detected immediately.', style: TextStyle(color: C.txtSecond, fontSize: 12, height: 1.6))),
                  ])),
              const SizedBox(height: 22),
              // Step 1 - ID
              _sh2(C, '1', 'Enter Evidence ID', Icons.tag_rounded, const Color(0xFF2563EB)),
              const SizedBox(height: 10),
              TextField(controller: _idCtrl, onChanged: (_) => setState((){}),
                  style: TextStyle(color: C.txtPrimary, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'e.g. 69b6b565ff08af25b2a44aa0',
                    hintStyle: TextStyle(color: C.txtMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.tag_rounded, size: 16, color: C.txtMuted),
                    helperText: 'Find the Evidence ID in the Blockchain Viewer or evidence detail page.',
                    helperStyle: TextStyle(color: C.txtMuted, fontSize: 11),
                    filled: true, fillColor: C.inputBg, isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: C.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: C.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  )),
              const SizedBox(height: 22),
              // Step 2 - File
              _sh2(C, '2', 'Upload the Same File', Icons.upload_file_outlined, const Color(0xFF7C3AED)),
              const SizedBox(height: 10),
              if (_file == null)
                MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: _pick,
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(color: C.inputBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border, width: 1.5)),
                        child: Column(children: [
                          Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.cloud_upload_outlined, size: 24, color: Color(0xFF7C3AED))),
                          const SizedBox(height: 10),
                          Text('Click to select the original file', style: TextStyle(color: C.txtPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Upload the exact same file that was originally submitted', textAlign: TextAlign.center, style: TextStyle(color: C.txtMuted, fontSize: 11)),
                          const SizedBox(height: 10),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(8)), child: const Text('Browse Files', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                        ]))))
              else
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: C.inputBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.4), width: 1.5)),
                    child: Row(children: [
                      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.insert_drive_file_outlined, size: 18, color: Color(0xFF7C3AED))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_file!.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.txtPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(_sz(_file!.size), style: TextStyle(color: C.txtSecond, fontSize: 11)),
                      ])),
                      GestureDetector(onTap: _pick, child: Container(width: 26, height: 26, decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF2563EB)))),
                      const SizedBox(width: 6),
                      GestureDetector(onTap: () => setState(() { _file = null; _result = null; }), child: Container(width: 26, height: 26, decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)))),
                    ])),
              const SizedBox(height: 22),
              if (_error != null) ...[
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFFECACA))),
                    child: Row(children: [const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16), const SizedBox(width: 10), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))), GestureDetector(onTap: () => setState(() => _error = null), child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 15))])),
                const SizedBox(height: 14),
              ],
              // Verify button
              SizedBox(width: double.infinity, height: 46,
                  child: ElevatedButton.icon(
                      onPressed: (_file != null && _idCtrl.text.isNotEmpty && !_verifying) ? _verify : null,
                      icon: _verifying ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                      label: Text(_verifying ? 'Verifying...' : _file == null ? 'Select a file first' : 'Verify Evidence Integrity', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), disabledBackgroundColor: const Color(0xFF059669).withOpacity(0.4), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
              // Result
              if (_result != null) ...[
                const SizedBox(height: 20),
                _resultCard(C),
              ],
            ]),
          )),
          // Right: info panel
          SizedBox(width: 270, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 28, 28, 28),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(13), border: Border.all(color: C.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(Icons.info_outline_rounded, size: 15, color: C.accent), const SizedBox(width: 7), Text('Verification Steps', style: TextStyle(color: C.txtPrimary, fontSize: 13, fontWeight: FontWeight.w700))]),
                    const SizedBox(height: 12),
                    for (final s in [
                      ['1', 'Enter the Evidence ID'],
                      ['2', 'Upload the original file'],
                      ['3', 'SHA-256 hash computed'],
                      ['4', 'Compared with MongoDB'],
                      ['5', 'Verified on Polygon blockchain'],
                      ['6', 'VERIFIED or TAMPERED result'],
                    ]) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 18, height: 18, decoration: BoxDecoration(color: C.accent.withOpacity(0.12), shape: BoxShape.circle), child: Center(child: Text(s[0], style: TextStyle(color: C.accent, fontSize: 9, fontWeight: FontWeight.w800)))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s[1], style: TextStyle(color: C.txtSecond, fontSize: 11, height: 1.4))),
                    ])),
                  ])),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.accent.withOpacity(isDark ? 0.08 : 0.05), borderRadius: BorderRadius.circular(13), border: Border.all(color: C.accent.withOpacity(0.2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(Icons.people_outline_rounded, size: 15, color: C.accent), const SizedBox(width: 7), Text('Who can verify', style: TextStyle(color: C.accent, fontSize: 13, fontWeight: FontWeight.w700))]),
                    const SizedBox(height: 10),
                    for (final r in [['🚔', 'Police Officer'], ['🔬', 'Forensic Expert'], ['⚖️', 'Prosecutor'], ['🛡️', 'Defense Attorney'], ['🏛️', 'Court Official']])
                      Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [Text(r[0], style: const TextStyle(fontSize: 13)), const SizedBox(width: 8), Text(r[1], style: TextStyle(color: C.txtSecond, fontSize: 12, fontWeight: FontWeight.w500))])),
                  ])),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _sh2(_C C, String n, String t, IconData i, Color color) => Row(children: [
    Container(width: 24, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: Center(child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)))),
    const SizedBox(width: 9), Icon(i, size: 14, color: color), const SizedBox(width: 7),
    Text(t, style: TextStyle(color: C.txtPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
    const SizedBox(width: 12), Expanded(child: Divider(color: C.border)),
  ]);

  Widget _resultCard(_C C) {
    final r = _result!;
    final ok = r['status'] == 'VERIFIED';
    final col = ok ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final bg = col.withOpacity(C.isDark ? 0.1 : 0.06);
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: col.withOpacity(0.3), width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: col.withOpacity(0.15), shape: BoxShape.circle), child: Icon(ok ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, size: 24, color: col)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ok ? 'Evidence Integrity CONFIRMED' : '⚠️  Evidence TAMPERED / COMPROMISED', style: TextStyle(color: col, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(r['message'] as String? ?? '', style: TextStyle(color: col.withOpacity(0.8), fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 16),
          Divider(color: col.withOpacity(0.2)),
          const SizedBox(height: 12),
          _row(C, 'Evidence ID', r['evidenceId'] as String? ?? '—', col: col, copy: true),
          _row(C, 'File Name', r['fileName'] as String? ?? '—'),
          _row(C, 'Hash Match', (r['hashMatch'] == true) ? '✓ Match' : '✗ Mismatch', col: r['hashMatch'] == true ? const Color(0xFF059669) : const Color(0xFFDC2626)),
          _row(C, 'Blockchain', r['blockchainValid'] == true ? '✓ Valid on-chain' : r['blockchainValid'] == false ? '✗ Invalid' : '— Not checked', col: r['blockchainValid'] == true ? const Color(0xFF059669) : r['blockchainValid'] == false ? const Color(0xFFDC2626) : C.txtMuted),
          if (!ok) ...[
            const SizedBox(height: 4),
            _row(C, 'Original Hash', _sh(r['originalHash'] as String? ?? ''), mono: true, copy: true, copyVal: r['originalHash'] as String?),
            _row(C, 'New Hash', _sh(r['newHash'] as String? ?? ''), mono: true, col: const Color(0xFFDC2626)),
          ],
          if (ok && r['blockchainTxHash'] != null) ...[
            const SizedBox(height: 4),
            _row(C, 'TX Hash', _sh(r['blockchainTxHash'] as String? ?? ''), mono: true, copy: true, copyVal: r['blockchainTxHash'] as String?),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => setState(() { _file = null; _result = null; if (widget.evidenceId == null) _idCtrl.clear(); }), icon: Icon(Icons.refresh_rounded, size: 14, color: col), label: Text('Verify Another', style: TextStyle(color: col, fontSize: 12)), style: OutlinedButton.styleFrom(side: BorderSide(color: col.withOpacity(0.4)), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.dashboard_outlined, color: Colors.white, size: 14), label: const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: col, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))))),
          ]),
        ]));
  }

  Widget _row(_C C, String l, String v, {Color? col, bool mono = false, bool copy = false, String? copyVal}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 100, child: Text(l, style: TextStyle(color: C.txtMuted, fontSize: 11))),
        Expanded(child: Text(v, style: TextStyle(color: col ?? C.txtPrimary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null))),
        if (copy) GestureDetector(onTap: () => _copy(copyVal ?? v, l), child: Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.copy_outlined, size: 12, color: C.txtMuted))),
      ]));
}

class _C {
  final bool isDark;
  _C(this.isDark);
  Color get bg => isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF0F4FF);
  Color get card => isDark ? const Color(0xFF111827) : Colors.white;
  Color get inputBg => isDark ? const Color(0xFF1A2540) : const Color(0xFFF8FAFF);
  Color get border => isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0);
  Color get txtPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get txtSecond => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get txtMuted => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
  Color get accent => const Color(0xFF2563EB);
}