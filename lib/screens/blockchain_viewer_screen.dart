// blockchain_viewer_screen.dart
// Premium Glassmorphism UI — fully responsive (mobile + tablet + desktop)
// FIXED: All RenderFlex overflow errors — Row at line 237 and all others
// All original logic 100% preserved.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

const double _kMobile = 600;
const double _kTablet = 1024;
const Color  _kPurple = Color(0xFF7C3AED);
const Color  _kGreen  = Color(0xFF059669);
const Color  _kAmber  = Color(0xFFD97706);
const Color  _kRed    = Color(0xFFEF4444);
const Color  _kBlue   = Color(0xFF2563EB);
const String _kContract = '0xac93065946CeADe04BD0233552177e33ea1dd651';

class BlockchainViewerScreen extends StatefulWidget {
  final String? txHash;
  final String? evidenceId;
  const BlockchainViewerScreen({super.key, this.txHash, this.evidenceId});

  @override
  State<BlockchainViewerScreen> createState() => _BlockchainViewerScreenState();
}

class _BlockchainViewerScreenState extends State<BlockchainViewerScreen>
    with TickerProviderStateMixin {

  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  List<dynamic>         _records      = [];
  bool                  _loading      = true;
  String?               _error;
  Map<String, dynamic>? _selected;
  String                _filterStatus = 'all';
  String                _searchQuery  = '';

  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _bgCtrl;
  late Animation<double>   _entryOpacity;
  late Animation<Offset>   _entrySlide;
  late Animation<double>   _pulse;
  late Animation<double>   _bgAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _entryOpacity = _entryCtrl.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: const Interval(0, 0.65))));
    _entrySlide   = _entryCtrl.drive(Tween(begin: const Offset(0, 0.03), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)));
    _pulse    = _pulseCtrl.drive(Tween(begin: 0.95, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)));
    _bgAnim   = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _entryCtrl.forward();
    _loadRecords();
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _pulseCtrl.dispose(); _bgCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Logic (all original, untouched) ──────────────────────────
  Future<void> _loadRecords() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getRecentEvidence(limit: 50);
      if (!mounted) return;
      setState(() {
        _records = data;
        _loading = false;
        if (widget.evidenceId != null) {
          final m = data.where((r) => r['_id'] == widget.evidenceId).toList();
          _selected = m.isNotEmpty ? Map<String, dynamic>.from(m.first) : null;
        } else if (widget.txHash != null) {
          final m = data.where((r) => r['blockchainTxHash'] == widget.txHash).toList();
          _selected = m.isNotEmpty ? Map<String, dynamic>.from(m.first) : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load records.'; _loading = false; });
    }
  }

  List<dynamic> get _filtered => _records.where((r) {
    if (_filterStatus != 'all' && r['blockchainStatus'] != _filterStatus) return false;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!(r['fileName'] ?? '').toLowerCase().contains(q) &&
          !(r['fileHash'] ?? '').toLowerCase().contains(q) &&
          !(r['blockchainTxHash'] ?? '').toLowerCase().contains(q) &&
          !(r['_id'] ?? '').toLowerCase().contains(q)) return false;
    }
    return true;
  }).toList();

  int get _anchored => _records.where((r) => r['blockchainStatus'] == 'anchored').length;
  int get _pending  => _records.where((r) => r['blockchainStatus'] == 'pending').length;
  int get _failed   => _records.where((r) => r['blockchainStatus'] == 'failed').length;

  void _openInBrowser(String url) {
    Clipboard.setData(ClipboardData(text: url));
    showDialog(context: context, builder: (_) => _UrlDialog(url: url,
        onClose: () => Navigator.pop(context),
        onCopy: () { Clipboard.setData(ClipboardData(text: url)); Navigator.pop(context); _snack('URL copied — paste in browser', _kPurple); }));
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('$label copied', _kGreen);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color,
        duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  String _txUrl(String txHash)  => 'https://amoy.polygonscan.com/tx/$txHash';
  String _contractUrl()          => 'https://amoy.polygonscan.com/address/$_kContract';
  String _qrData(Map<String, dynamic> r) {
    final txHash = r['blockchainTxHash'] as String?;
    if (txHash != null && txHash.isNotEmpty) return _txUrl(txHash);
    return 'https://amoy.polygonscan.com/search?f=0&q=${r['_id'] ?? ''}';
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: Stack(children: [
        Positioned.fill(child: _BgAnim(anim: _bgAnim)),
        SafeArea(child: FadeTransition(opacity: _entryOpacity,
            child: SlideTransition(position: _entrySlide,
                child: Column(children: [
                  _buildAppBar(),
                  Expanded(child: _buildBody()),
                ])))),
      ]),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────
  Widget _buildAppBar() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.70),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
        child: Row(children: [
          _ABBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 6),
          Container(width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [_kPurple, Color(0xFF4F46E5)])),
              child: const Icon(Icons.link_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Flexible(child: Text('Blockchain Viewer', overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3))),
          const SizedBox(width: 10),
          AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) =>
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _kGreen.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kGreen.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Transform.scale(scale: _pulse.value,
                        child: Container(width: 6, height: 6,
                            decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle))),
                    const SizedBox(width: 5),
                    const Text('Polygon Amoy',
                        style: TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                  ]))),
          const Spacer(),
          _ABBtn(icon: Icons.refresh_rounded, onTap: _loadRecords),
          const SizedBox(width: 4),
          GestureDetector(onTap: () => _openInBrowser(_contractUrl()),
              child: Container(margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _kPurple.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kPurple.withOpacity(0.25))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.open_in_new_rounded, size: 12, color: _kPurple),
                    SizedBox(width: 4),
                    Text('Contract', style: TextStyle(color: _kPurple, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]))),
          const SizedBox(width: 4),
        ]),
      ),
    ));
  }

  // ── Responsive body ───────────────────────────────────────────
  Widget _buildBody() {
    return LayoutBuilder(builder: (_, constraints) {
      final w        = constraints.maxWidth;
      final isMobile = w < _kMobile;

      if (isMobile) {
        // On mobile: list view, tap opens detail in new page-like overlay
        return Column(children: [
          _statsBar(),
          _searchBar(),
          Expanded(child: _loading
              ? _shimmerList()
              : _error != null
              ? _errorState()
              : _filtered.isEmpty
              ? _emptyList()
              : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _tile(_filtered[i]))),
        ]);
      }

      // Tablet/Desktop: split view
      return Row(children: [
        SizedBox(width: w < _kTablet ? 340 : 400,
            child: Column(children: [
              _statsBar(), _searchBar(),
              Expanded(child: _loading
                  ? _shimmerList()
                  : _error != null ? _errorState()
                  : _filtered.isEmpty ? _emptyList()
                  : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _tile(_filtered[i]))),
            ])),
        Container(width: 1, color: Colors.white.withOpacity(0.6)),
        Expanded(child: _selected == null ? _emptyState() : _detail(_selected!)),
      ]);
    });
  }

  // ── Stats Bar ─────────────────────────────────────────────────
  Widget _statsBar() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.60),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _statChip('Total',   '${_records.length}', _kBlue),
                const SizedBox(width: 7),
                _statChip('Anchored', '$_anchored', _kGreen),
                const SizedBox(width: 7),
                _statChip('Pending',  '$_pending',  _kAmber),
                const SizedBox(width: 7),
                _statChip('Failed',   '$_failed',   _kRed),
              ])),
        )));
  }

  Widget _statChip(String label, String val, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.22))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
        Text(val, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]));

  // ── Search Bar ────────────────────────────────────────────────
  Widget _searchBar() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.55),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
          child: Column(children: [
            // Search field
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search filename, hash, TX, ID...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF9CA3AF)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF9CA3AF)),
                    onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                    : null,
                filled: true, fillColor: Colors.white.withOpacity(0.75),
                isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kPurple, width: 1.8)),
              ),
            ),
            const SizedBox(height: 9),
            // Filter pills
            SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final s in ['all', 'anchored', 'pending', 'failed'])
                    Padding(padding: const EdgeInsets.only(right: 7), child: _filterPill(s)),
                ])),
          ]),
        )));
  }

  Widget _filterPill(String s) {
    final active = _filterStatus == s;
    final color  = _statusColor(s);
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = s),
      child: AnimatedContainer(duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: active ? color : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? color : const Color(0xFFD1D5DB), width: 1.2)),
          child: Text(s == 'all' ? 'All' : _cap(s),
              style: TextStyle(color: active ? Colors.white : const Color(0xFF475569),
                  fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400))),
    );
  }

  // ── List tile ─────────────────────────────────────────────────
  Widget _tile(Map record) {
    final isSel  = _selected?['_id'] == record['_id'];
    final status = record['blockchainStatus'] ?? 'pending';
    final color  = _statusColor(status);
    final txHash = record['blockchainTxHash'] as String?;
    final name   = record['fileName'] ?? 'Unknown';

    return MouseRegion(cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _selected = Map<String, dynamic>.from(record));
          // On mobile, show detail as bottom sheet
          if (MediaQuery.of(context).size.width < _kMobile) {
            showModalBottomSheet(
              context: context, isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95,
                builder: (_, ctrl) => _GlassCard(
                    child: _detail(_selected!, scrollController: ctrl)),
              ),
            );
          }
        },
        child: AnimatedContainer(duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSel ? _kPurple.withOpacity(0.06) : Colors.white.withOpacity(0.68),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isSel ? _kPurple.withOpacity(0.35) : Colors.white.withOpacity(0.8),
                width: isSel ? 1.5 : 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2))),
                child: Icon(_statusIcon(status), size: 17, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              txHash != null
                  ? Text(txHash.length > 20 ? '${txHash.substring(0, 10)}…${txHash.substring(txHash.length - 8)}' : txHash,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _kPurple, fontSize: 10, fontFamily: 'monospace'))
                  : Text(status == 'pending' ? 'Anchoring...' : 'Not anchored',
                  style: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 10)),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _badge(status),
              const SizedBox(height: 3),
              Text(_timeAgo(record['createdAt']),
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Detail panel ──────────────────────────────────────────────
  Widget _detail(Map<String, dynamic> r, {ScrollController? scrollController}) {
    final status   = (r['blockchainStatus'] ?? 'pending') as String;
    final txHash   = r['blockchainTxHash'] as String?;
    final fileHash = r['fileHash'] as String?;
    final fileName = (r['fileName'] ?? '—') as String;
    final evId     = (r['_id'] ?? '') as String;
    final anchored = status == 'anchored';
    final color    = _statusColor(status);
    final qrContent = _qrData(r);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ────────────────────────────────────────
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2))),
              child: Icon(_statusIcon(status), size: 22, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fileName, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            _badge(status),
          ])),
        ]),
        const SizedBox(height: 18),

        // ── CTA buttons ───────────────────────────────────
        if (anchored && txHash != null) ...[
          _GradBtn(label: 'View on Polygonscan', icon: Icons.open_in_new_rounded,
              color: _kPurple, onTap: () => _openInBrowser(_txUrl(txHash))),
          const SizedBox(height: 10),
        ],
        Row(children: [
          if (txHash != null) ...[
            Expanded(child: _OutlineBtn(label: 'Copy TX Hash', icon: Icons.copy_rounded,
                color: _kPurple, onTap: () => _copy(txHash, 'Transaction hash'))),
            const SizedBox(width: 8),
          ],
          if (fileHash != null)
            Expanded(child: _OutlineBtn(label: 'Copy File Hash', icon: Icons.fingerprint_rounded,
                color: _kGreen, onTap: () => _copy(fileHash, 'File hash'))),
        ]),
        const SizedBox(height: 20),

        // ── Evidence Details ──────────────────────────────
        _secTitle('Evidence Details', Icons.insert_drive_file_outlined),
        const SizedBox(height: 10),
        _detailCard([
          _drow('Evidence ID',  evId,                         copy: evId),
          _drow('File Name',    fileName),
          _drow('File Type',    (r['fileType'] ?? '—') as String),
          _drow('File Size',    _fmtSize(r['fileSize'])),
          _drow('Evidence Type',_cap((r['evidenceType'] ?? 'document') as String)),
          _drow('Uploaded By',  (r['uploadedBy'] ?? '—') as String, copy: r['uploadedBy'] as String?),
          _drow('Uploaded At',  _fmtDate(r['createdAt'] as String?)),
          _drow('Case ID',      (r['caseId'] ?? '—') as String, copy: r['caseId'] as String?),
          if ((r['description'] ?? '').toString().isNotEmpty)
            _drow('Description', r['description'] as String),
        ]),
        const SizedBox(height: 18),

        // ── SHA-256 Hash ──────────────────────────────────
        _secTitle('SHA-256 Fingerprint', Icons.fingerprint_rounded),
        const SizedBox(height: 10),
        fileHash != null ? _hashBox(fileHash) : _emptyBox('No hash available'),
        const SizedBox(height: 18),

        // ── Blockchain Record ─────────────────────────────
        _secTitle('Blockchain Record', Icons.link_rounded),
        const SizedBox(height: 10),
        _detailCard([
          _drow('Network',    'Polygon Amoy Testnet'),
          _drow('Chain ID',   '80002'),
          _drow('Status',     _cap(status), valueColor: color),
          if (txHash != null)
            _drow('TX Hash', txHash, copy: txHash, mono: true),
          if (r['anchoredAt'] != null)
            _drow('Anchored At', _fmtDate(r['anchoredAt'] as String?)),
          _drow('Contract', _kContract, copy: _kContract, mono: true),
        ]),

        if (anchored && txHash != null) ...[
          const SizedBox(height: 10),
          GestureDetector(onTap: () => _openInBrowser(_txUrl(txHash)),
            child: Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _kPurple.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kPurple.withOpacity(0.22))),
                child: Row(children: [
                  const Icon(Icons.launch_rounded, size: 16, color: _kPurple),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Open on Polygonscan →',
                        style: TextStyle(color: _kPurple, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_txUrl(txHash), overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _kPurple.withOpacity(0.65), fontSize: 10, fontFamily: 'monospace')),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: _kPurple),
                ])),
          ),
        ],
        const SizedBox(height: 18),

        // ── QR Code ───────────────────────────────────────
        _secTitle('Blockchain QR Code', Icons.qr_code_2_rounded),
        const SizedBox(height: 6),
        Text(anchored && txHash != null
            ? 'Scan to open this transaction directly on Polygonscan'
            : 'QR will link to Polygonscan once anchored',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
        const SizedBox(height: 12),
        _GlassCard(child: Padding(padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // QR image
                Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: QrImageView(data: qrContent, version: QrVersions.auto, size: 110,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)),
                        errorStateBuilder: (_, __) => const Icon(Icons.error_outline, color: Colors.red))),
                const SizedBox(width: 14),
                // QR URL content - FIXED: use Flexible to prevent overflow
                Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('QR Content',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kPurple.withOpacity(0.2))),
                      child: SelectableText(qrContent,
                          style: const TextStyle(color: _kPurple, fontSize: 10, fontFamily: 'monospace'))),
                  const SizedBox(height: 10),
                  // FIXED: use Wrap instead of Row to prevent overflow on narrow screens
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _miniBtn('Copy URL', Icons.copy_rounded, () => _copy(qrContent, 'QR URL')),
                    _miniBtn('Open URL', Icons.open_in_new_rounded, () => _openInBrowser(qrContent)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Scan this QR to go directly to the Polygonscan transaction.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, height: 1.5)),
                ])),
              ]),
            ]))),
        const SizedBox(height: 18),

        // ── Integrity Summary ─────────────────────────────
        _secTitle('Integrity Summary', Icons.verified_user_outlined),
        const SizedBox(height: 10),
        _GlassCard(child: Padding(padding: const EdgeInsets.all(14),
            child: Column(children: [
              _checkRow('File uploaded to storage',   true,          'Stored in Firebase Storage'),
              _checkRow('SHA-256 hash generated',     fileHash != null, 'Cryptographic fingerprint computed'),
              _checkRow('Metadata saved',             true,          'Saved to MongoDB'),
              _checkRow('Blockchain anchored',        anchored,
                  anchored ? 'TX confirmed on Polygon Amoy'
                      : status == 'pending' ? 'Anchoring in progress...' : 'Anchoring failed'),
            ]))),
        const SizedBox(height: 30),
      ]),
    );
  }

  // ── Empty / Error states ──────────────────────────────────────
  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 68, height: 68,
        decoration: BoxDecoration(color: _kPurple.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.touch_app_outlined, size: 32, color: _kPurple)),
    const SizedBox(height: 14),
    const Text('Select a record', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6),
    const Text('Click any record on the left\nto view blockchain details.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5)),
  ]));

  Widget _emptyList() => const Center(child: Text('No records found',
      style: TextStyle(color: Color(0xFF64748B), fontSize: 13)));

  Widget _errorState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline_rounded, color: Color(0xFF9CA3AF), size: 34),
    const SizedBox(height: 8),
    Text(_error!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
    const SizedBox(height: 10),
    TextButton(onPressed: _loadRecords, child: const Text('Retry', style: TextStyle(color: _kPurple))),
  ]));

  Widget _shimmerList() => ListView.builder(
      padding: const EdgeInsets.all(10), itemCount: 6,
      itemBuilder: (_, __) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.8))),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 11, color: Colors.grey.shade200),
              const SizedBox(height: 6),
              Container(height: 10, width: 120, color: Colors.grey.shade200),
            ])),
          ])));

  // ── Reusable detail widgets ───────────────────────────────────
  Widget _secTitle(String t, IconData i) => Row(children: [
    Container(width: 28, height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _kPurple.withOpacity(0.08)),
        child: Icon(i, size: 14, color: _kPurple)),
    const SizedBox(width: 8),
    Text(t, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
  ]);

  Widget _detailCard(List<Widget> rows) => _GlassCard(
      child: Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          child: Column(children: rows)));

  Widget _drow(String label, String value, {String? copy, bool mono = false, Color? valueColor}) {
    return Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 86,
              child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11))),
          // FIXED: use Flexible + SelectableText so long values wrap instead of overflow
          Flexible(child: SelectableText(value.isEmpty ? '—' : value,
              style: TextStyle(color: valueColor ?? const Color(0xFF0F172A),
                  fontSize: 12, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null))),
          if (copy != null && copy.isNotEmpty)
            GestureDetector(onTap: () => _copy(copy, label),
                child: const Padding(padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.copy_outlined, size: 12, color: Color(0xFF9CA3AF)))),
        ]));
  }

  Widget _hashBox(String hash) => _GlassCard(
      tint: const Color(0xFFF0FDF4),
      child: Padding(padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.fingerprint_rounded, size: 15, color: _kGreen),
            const SizedBox(width: 10),
            Flexible(child: SelectableText(hash,
                style: const TextStyle(color: _kGreen, fontSize: 11, fontFamily: 'monospace', height: 1.6))),
            GestureDetector(onTap: () => _copy(hash, 'SHA-256 hash'),
                child: const Padding(padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.copy_outlined, size: 12, color: _kGreen))),
          ])));

  Widget _emptyBox(String msg) => Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD1D5DB))),
      child: Text(msg, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)));

  Widget _checkRow(String title, bool done, String sub) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 22, height: 22,
            decoration: BoxDecoration(
                color: done ? _kGreen.withOpacity(0.10) : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: done ? _kGreen.withOpacity(0.35) : const Color(0xFFD1D5DB))),
            child: Icon(done ? Icons.check_rounded : Icons.hourglass_empty_rounded,
                size: 12, color: done ? _kGreen : const Color(0xFF9CA3AF))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
          Text(sub,   style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        ])),
      ]));

  Widget _badge(String status) {
    final color = _statusColor(status);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Text(_cap(status), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));
  }

  Widget _miniBtn(String label, IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: _kPurple),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: _kPurple, fontSize: 11, fontWeight: FontWeight.w600)),
          ])));

  // ── Helpers ───────────────────────────────────────────────────
  Color _statusColor(String s) => switch (s) {
    'anchored' => _kGreen, 'pending' => _kAmber,
    'failed'   => _kRed,  'all'     => _kBlue,
    _          => const Color(0xFF9CA3AF),
  };

  IconData _statusIcon(String s) => switch (s) {
    'anchored' => Icons.verified_rounded, 'pending' => Icons.hourglass_bottom_rounded,
    'failed'   => Icons.error_outline_rounded, _ => Icons.help_outline_rounded,
  };

  String _cap(String s)     => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  String _timeAgo(String? raw) {
    if (raw == null) return '—';
    final t = DateTime.tryParse(raw); if (t == null) return '—';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1)  return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours   < 24) return '${d.inHours}h ago';
    if (d.inDays    < 7)  return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final t = DateTime.tryParse(raw); if (t == null) return raw;
    final l = t.toLocal();
    return '${l.day.toString().padLeft(2,'0')}/${l.month.toString().padLeft(2,'0')}/${l.year}  ${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}';
  }
  String _fmtSize(dynamic b) {
    if (b == null) return '—';
    final n = b is int ? b : int.tryParse('$b') ?? 0;
    if (n < 1024)       return '$n B';
    if (n < 1048576)    return '${(n / 1024).toStringAsFixed(1)} KB';
    if (n < 1073741824) return '${(n / 1048576).toStringAsFixed(1)} MB';
    return '${(n / 1073741824).toStringAsFixed(1)} GB';
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _BgAnim extends StatelessWidget {
  final Animation<double> anim;
  const _BgAnim({required this.anim});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: anim, builder: (_, __) {
    final t = anim.value;
    return Container(color: const Color(0xFFEEF2FF), child: Stack(children: [
      Positioned(left: -110 + t * 60, top: -80 + t * 50, child: _orb(300, _kPurple, 0.11)),
      Positioned(right: -70 + t * 35, bottom: 30 + t * 70, child: _orb(250, _kBlue,  0.09)),
      Positioned(left: MediaQuery.of(context).size.width * 0.4,
          top: MediaQuery.of(context).size.height * 0.35 - t * 45,
          child: _orb(180, const Color(0xFF4F46E5), 0.08)),
    ]));
  });
  Widget _orb(double sz, Color c, double op) => Container(width: sz, height: sz,
      decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c.withOpacity(op), c.withOpacity(0)])));
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? tint;
  const _GlassCard({required this.child, this.tint});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -2),
            BoxShadow(color: Colors.white.withOpacity(0.85), blurRadius: 1, offset: const Offset(0, -1))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.2),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [(tint ?? Colors.white).withOpacity(0.88), (tint ?? Colors.white).withOpacity(0.55)])),
                  child: child))));
}

class _GradBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _GradBtn({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 46,
      child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          color: color, boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))]),
          child: Material(color: Colors.transparent,
              child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 8),
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ])))));
}

class _OutlineBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(height: 42,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.6), border: Border.all(color: color.withOpacity(0.3), width: 1.3)),
      child: Material(color: Colors.transparent,
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 14, color: color), const SizedBox(width: 7),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
              ]))));
}

class _ABBtn extends StatefulWidget {
  final IconData icon; final VoidCallback onTap;
  const _ABBtn({required this.icon, required this.onTap});
  @override State<_ABBtn> createState() => _ABBtnState();
}
class _ABBtnState extends State<_ABBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap,
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              width: 36, height: 36,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  color: _h ? _kPurple.withOpacity(0.08) : Colors.transparent,
                  border: Border.all(color: _h ? _kPurple.withOpacity(0.2) : Colors.transparent)),
              child: Icon(widget.icon, size: 18, color: _h ? _kPurple : const Color(0xFF475569)))));
}

class _UrlDialog extends StatelessWidget {
  final String url;
  final VoidCallback onClose, onCopy;
  const _UrlDialog({required this.url, required this.onClose, required this.onCopy});
  @override
  Widget build(BuildContext context) => Dialog(backgroundColor: Colors.transparent,
      child: ClipRRect(borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0xFFFAFBFF), Color(0xFFEEF2FF)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                      boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 16))]),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: _kPurple.withOpacity(0.1)),
                          child: const Icon(Icons.open_in_new_rounded, size: 16, color: _kPurple)),
                      const SizedBox(width: 10),
                      const Text('Open in Browser', style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 14),
                    const Text('URL copied to clipboard. Paste in your browser:',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10), border: Border.all(color: _kPurple.withOpacity(0.2))),
                        child: SelectableText(url, style: const TextStyle(color: _kPurple, fontSize: 11, fontFamily: 'monospace'))),
                    const SizedBox(height: 8),
                    const Row(children: [
                      Icon(Icons.check_circle_outline_rounded, size: 14, color: _kGreen),
                      SizedBox(width: 6),
                      Text('URL copied to clipboard', style: TextStyle(color: _kGreen, fontSize: 12)),
                    ]),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: GestureDetector(onTap: onClose,
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.8))),
                              child: const Center(child: Text('Close', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)))))),
                      const SizedBox(width: 10),
                      Expanded(child: GestureDetector(onTap: onCopy,
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
                              child: const Center(child: Text('Copy Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
                    ]),
                  ])))));
}