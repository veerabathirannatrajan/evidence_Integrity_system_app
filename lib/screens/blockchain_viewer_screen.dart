import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

// url_launcher removed — we use Clipboard + js interop for web/Windows
// which avoids MissingPluginException entirely

class BlockchainViewerScreen extends StatefulWidget {
  final String? txHash;
  final String? evidenceId;
  const BlockchainViewerScreen({super.key, this.txHash, this.evidenceId});

  @override
  State<BlockchainViewerScreen> createState() =>
      _BlockchainViewerScreenState();
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
  late Animation<double>   _entryOpacity;
  late Animation<Offset>   _entrySlide;
  late Animation<double>   _pulse;

  static const String _contractAddress =
      '0xac93065946CeADe04BD0233552177e33ea1dd651';

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _entryOpacity = _entryCtrl.drive(Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: const Interval(0, 0.6))));
    _entrySlide = _entryCtrl.drive(
        Tween(begin: const Offset(0, 0.03), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)));
    _pulse = _pulseCtrl.drive(Tween(begin: 0.95, end: 1.05)
        .chain(CurveTween(curve: Curves.easeInOut)));
    _entryCtrl.forward();
    _loadRecords();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

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
          final m = data.where(
                  (r) => r['blockchainTxHash'] == widget.txHash).toList();
          _selected = m.isNotEmpty ? Map<String, dynamic>.from(m.first) : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load records.'; _loading = false; });
    }
  }

  List<dynamic> get _filtered => _records.where((r) {
    if (_filterStatus != 'all' &&
        r['blockchainStatus'] != _filterStatus) return false;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!(r['fileName'] ?? '').toLowerCase().contains(q) &&
          !(r['fileHash'] ?? '').toLowerCase().contains(q) &&
          !(r['blockchainTxHash'] ?? '').toLowerCase().contains(q) &&
          !(r['_id'] ?? '').toLowerCase().contains(q)) return false;
    }
    return true;
  }).toList();

  int get _anchored =>
      _records.where((r) => r['blockchainStatus'] == 'anchored').length;
  int get _pending =>
      _records.where((r) => r['blockchainStatus'] == 'pending').length;
  int get _failed =>
      _records.where((r) => r['blockchainStatus'] == 'failed').length;

  // ── Open URL — works on ALL platforms without url_launcher ──
  // Copies URL and shows a button to open it
  void _openInBrowser(String url) {
    // Copy URL to clipboard first
    Clipboard.setData(ClipboardData(text: url));
    // Show dialog with clickable link
    showDialog(
      context: context,
      builder: (_) {
        final isDark = context.read<ThemeProvider>().isDark;
        final C = _C(isDark);
        return AlertDialog(
          backgroundColor: C.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          title: Row(children: [
            Icon(Icons.open_in_new_rounded,
                color: const Color(0xFF7C3AED), size: 18),
            const SizedBox(width: 8),
            Text('Open in Browser',
                style: TextStyle(color: C.txtPrimary,
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('URL copied to clipboard. Paste in your browser:',
                  style: TextStyle(color: C.txtSecond, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: C.inputBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: C.border)),
                child: SelectableText(
                  url,
                  style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Text('URL copied to clipboard',
                    style: TextStyle(
                        color: const Color(0xFF059669), fontSize: 12)),
              ]),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close',
                    style: TextStyle(color: C.txtSecond))),
            ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  Navigator.pop(context);
                  _snack('URL copied — paste in browser', const Color(0xFF7C3AED));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('Copy Again',
                    style: TextStyle(color: Colors.white))),
          ],
        );
      },
    );
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('$label copied', const Color(0xFF059669));
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── URL builders ─────────────────────────────────────────────
  String _txUrl(String txHash) =>
      'https://amoy.polygonscan.com/tx/$txHash';
  String _contractUrl() =>
      'https://amoy.polygonscan.com/address/$_contractAddress';

  // QR encodes the real Polygonscan TX URL so anyone can scan
  // and go directly to the transaction
  String _qrData(Map<String, dynamic> r) {
    final txHash = r['blockchainTxHash'] as String?;
    if (txHash != null && txHash.isNotEmpty) {
      return _txUrl(txHash);
    }
    // Fallback: encode the evidence ID
    return 'https://amoy.polygonscan.com/search?f=0&q=${r['_id'] ?? ''}';
  }

  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final C      = _C(isDark);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildAppBar(C),
      body: FadeTransition(
        opacity: _entryOpacity,
        child: SlideTransition(
          position: _entrySlide,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 420,
                child: Column(children: [
                  _statsBar(C),
                  _searchBar(C),
                  Expanded(child: _list(C)),
                ]),
              ),
              VerticalDivider(color: C.border, width: 1),
              Expanded(
                child: _selected == null
                    ? _emptyState(C)
                    : _detail(C, _selected!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(_C C) {
    return AppBar(
      backgroundColor: C.card,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: C.txtPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.link_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text('Blockchain Viewer',
            style: TextStyle(color: C.txtPrimary,
                fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Transform.scale(scale: _pulse.value,
                  child: Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle))),
              const SizedBox(width: 5),
              const Text('Polygon Amoy',
                  style: TextStyle(color: Color(0xFF059669),
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
      actions: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openInBrowser(_contractUrl()),
            child: Container(
              margin: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.open_in_new_rounded,
                    size: 13, color: Color(0xFF7C3AED)),
                const SizedBox(width: 5),
                const Text('View Contract',
                    style: TextStyle(color: Color(0xFF7C3AED),
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              color: C.txtSecond, size: 18),
          onPressed: _loadRecords,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: C.border, height: 1)),
    );
  }

  Widget _statsBar(_C C) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: C.card,
          border: Border(bottom: BorderSide(color: C.border))),
      child: Row(children: [
        _chip(C, 'Total', '${_records.length}', C.accent),
        const SizedBox(width: 8),
        _chip(C, 'Anchored', '$_anchored', const Color(0xFF059669)),
        const SizedBox(width: 8),
        _chip(C, 'Pending', '$_pending', const Color(0xFFD97706)),
        const SizedBox(width: 8),
        _chip(C, 'Failed', '$_failed', const Color(0xFFEF4444)),
      ]),
    );
  }

  Widget _chip(_C C, String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ',
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
        Text(val,
            style: TextStyle(color: color,
                fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _searchBar(_C C) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
          color: C.card,
          border: Border(bottom: BorderSide(color: C.border))),
      child: Column(children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(color: C.txtPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search filename, hash, TX, ID...',
            hintStyle: TextStyle(color: C.txtMuted, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded,
                size: 16, color: C.txtMuted),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 14, color: C.txtMuted),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                })
                : null,
            filled: true,
            fillColor: C.inputBg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: C.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: C.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: C.accent, width: 1.5)),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          for (final s in ['all', 'anchored', 'pending', 'failed'])
            Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _filterPill(C, s)),
        ]),
      ]),
    );
  }

  Widget _filterPill(_C C, String s) {
    final active = _filterStatus == s;
    final color  = _statusColor(s);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: active ? color : C.inputBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? color : C.border)),
          child: Text(s == 'all' ? 'All' : _cap(s),
              style: TextStyle(
                  color: active ? Colors.white : C.txtSecond,
                  fontSize: 11,
                  fontWeight: active
                      ? FontWeight.w700 : FontWeight.w400)),
        ),
      ),
    );
  }

  Widget _list(_C C) {
    if (_loading) {
      return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: 6,
          itemBuilder: (_, __) => _shimmerTile(C));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: C.txtMuted, size: 34),
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: C.txtSecond, fontSize: 13)),
            const SizedBox(height: 10),
            TextButton(onPressed: _loadRecords,
                child: Text('Retry',
                    style: TextStyle(color: C.accent))),
          ]));
    }
    if (_filtered.isEmpty) {
      return Center(child: Text('No records found',
          style: TextStyle(color: C.txtSecond, fontSize: 13)));
    }
    return ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _tile(C, _filtered[i]));
  }

  Widget _tile(_C C, Map record) {
    final isSel  = _selected?['_id'] == record['_id'];
    final status = record['blockchainStatus'] ?? 'pending';
    final color  = _statusColor(status);
    final txHash = record['blockchainTxHash'] as String?;
    final name   = record['fileName'] ?? 'Unknown';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() =>
        _selected = Map<String, dynamic>.from(record)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: isSel ? C.accent.withOpacity(0.08) : C.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSel ? C.accent.withOpacity(0.4) : C.border,
                  width: isSel ? 1.5 : 1)),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(_statusIcon(status),
                  size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: C.txtPrimary,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                txHash != null
                    ? Text(
                  // Display only - show first 10 + last 8 chars
                    txHash.length > 18
                        ? '${txHash.substring(0, 10)}...${txHash.substring(txHash.length - 8)}'
                        : txHash,
                    style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 10, fontFamily: 'monospace'))
                    : Text(
                    status == 'pending' ? 'Anchoring...' : 'Not anchored',
                    style: TextStyle(color: C.txtMuted, fontSize: 10)),
              ],
            )),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _badge(status),
                  const SizedBox(height: 4),
                  Text(_timeAgo(record['createdAt']),
                      style: TextStyle(color: C.txtMuted, fontSize: 10)),
                ]),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // DETAIL PANEL
  // ════════════════════════════════════════════════════════════
  Widget _detail(_C C, Map<String, dynamic> r) {
    final status     = (r['blockchainStatus'] ?? 'pending') as String;
    final txHash     = r['blockchainTxHash'] as String?;
    final fileHash   = r['fileHash'] as String?;
    final fileName   = (r['fileName'] ?? '—') as String;
    final evidenceId = (r['_id'] ?? '') as String;
    final anchored   = status == 'anchored';
    final color      = _statusColor(status);

    // QR encodes the real Polygonscan TX page URL
    final qrContent  = _qrData(r);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(_statusIcon(status), size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: C.txtPrimary,
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                _badge(status),
              ],
            )),
          ]),

          const SizedBox(height: 20),

          // Main CTA
          if (anchored && txHash != null) ...[
            SizedBox(
              width: double.infinity, height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _openInBrowser(_txUrl(txHash)),
                icon: const Icon(Icons.open_in_new_rounded,
                    color: Colors.white, size: 16),
                label: const Text('View on Polygonscan',
                    style: TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Copy buttons
          Row(children: [
            if (txHash != null) ...[
              Expanded(
                child: _outlineBtn(C, 'Copy Full TX Hash',
                    Icons.copy_rounded,
                    // copy the COMPLETE unhashed tx
                        () => _copy(txHash, 'Transaction hash')),
              ),
              const SizedBox(width: 8),
            ],
            if (fileHash != null)
              Expanded(
                child: _outlineBtn(C, 'Copy File Hash',
                    Icons.fingerprint_rounded,
                        () => _copy(fileHash, 'File hash')),
              ),
          ]),

          const SizedBox(height: 20),
          Divider(color: C.border),
          const SizedBox(height: 16),

          // ── Evidence Details ─────────────────────────────
          _secTitle(C, 'Evidence Details',
              Icons.insert_drive_file_outlined),
          const SizedBox(height: 12),

          _card(C, [
            // Evidence ID — always shown, full value
            _row(C, 'Evidence ID', evidenceId,
                copy: evidenceId),
            _row(C, 'File Name', fileName),
            _row(C, 'File Type',
                (r['fileType'] ?? '—') as String),
            _row(C, 'File Size', _fmtSize(r['fileSize'])),
            _row(C, 'Evidence Type',
                _cap((r['evidenceType'] ?? 'document') as String)),
            _row(C, 'Uploaded By',
                (r['uploadedBy'] ?? '—') as String,
                copy: r['uploadedBy'] as String?),
            // Uploaded At — converted from ISO to readable
            _row(C, 'Uploaded At',
                _fmtDate(r['createdAt'] as String?)),
            _row(C, 'Case ID',
                (r['caseId'] ?? '—') as String,
                copy: r['caseId'] as String?),
            if ((r['description'] ?? '').toString().isNotEmpty)
              _row(C, 'Description',
                  r['description'] as String),
          ]),

          const SizedBox(height: 20),

          // ── SHA-256 Hash ─────────────────────────────────
          _secTitle(C, 'SHA-256 Fingerprint',
              Icons.fingerprint_rounded),
          const SizedBox(height: 12),

          fileHash != null
              ? _hashBox(C, fileHash)
              : _emptyBox(C, 'No hash available'),

          const SizedBox(height: 20),

          // ── Blockchain Record ─────────────────────────────
          _secTitle(C, 'Blockchain Record', Icons.link_rounded),
          const SizedBox(height: 12),

          _card(C, [
            _row(C, 'Network', 'Polygon Amoy Testnet'),
            _row(C, 'Chain ID', '80002'),
            _row(C, 'Status', _cap(status), valueColor: color),
            if (txHash != null)
            // Full TX hash — not truncated
              _row(C, 'TX Hash', txHash,
                  copy: txHash, mono: true),
            if (r['anchoredAt'] != null)
              _row(C, 'Anchored At',
                  _fmtDate(r['anchoredAt'] as String?)),
            // Full contract address — copyable
            _row(C, 'Contract', _contractAddress,
                copy: _contractAddress, mono: true),
          ]),

          // Polygonscan link card
          if (anchored && txHash != null) ...[
            const SizedBox(height: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openInBrowser(_txUrl(txHash)),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF7C3AED).withOpacity(0.25))),
                  child: Row(children: [
                    const Icon(Icons.launch_rounded,
                        size: 16, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Open on Polygonscan →',
                            style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        SelectableText(
                            _txUrl(txHash),
                            style: TextStyle(
                                color: const Color(0xFF7C3AED)
                                    .withOpacity(0.7),
                                fontSize: 10,
                                fontFamily: 'monospace')),
                      ],
                    )),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 11, color: Color(0xFF7C3AED)),
                  ]),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── QR Code ──────────────────────────────────────
          _secTitle(C, 'Blockchain QR Code',
              Icons.qr_code_2_rounded),
          const SizedBox(height: 6),
          Text(
              anchored && txHash != null
                  ? 'Scan to open this transaction directly on Polygonscan'
                  : 'QR will link to Polygonscan once anchored',
              style: TextStyle(color: C.txtMuted, fontSize: 11)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real QR — encodes the Polygonscan TX URL
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: C.border)),
                  child: QrImageView(
                    // QR data = real Polygonscan URL
                    data: qrContent,
                    version: QrVersions.auto,
                    size: 120,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F172A)),
                    dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A)),
                    errorStateBuilder: (_, __) => const Icon(
                        Icons.error_outline, color: Colors.red),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR Content',
                        style: TextStyle(color: C.txtPrimary,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: C.inputBg,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: C.border)),
                      child: SelectableText(
                          qrContent,
                          style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 10,
                              fontFamily: 'monospace')),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      _miniBtn(C, 'Copy URL',
                          Icons.copy_rounded,
                              () => _copy(qrContent, 'QR URL')),
                      const SizedBox(width: 8),
                      _miniBtn(C, 'Open URL',
                          Icons.open_in_new_rounded,
                              () => _openInBrowser(qrContent)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        'Anyone who scans this QR will be taken '
                            'directly to the Polygonscan transaction.',
                        style: TextStyle(
                            color: C.txtMuted, fontSize: 10,
                            height: 1.5)),
                  ],
                )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Integrity Checklist ───────────────────────────
          _secTitle(C, 'Integrity Summary',
              Icons.verified_user_outlined),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border)),
            child: Column(children: [
              _checkRow(C, 'File uploaded to storage',
                  true, 'Stored in Firebase Storage'),
              _checkRow(C, 'SHA-256 hash generated',
                  fileHash != null,
                  'Cryptographic fingerprint computed'),
              _checkRow(C, 'Metadata saved',
                  true, 'Saved to MongoDB'),
              _checkRow(C, 'Blockchain anchored',
                  anchored,
                  anchored
                      ? 'TX confirmed on Polygon Amoy'
                      : status == 'pending'
                      ? 'Anchoring in progress...'
                      : 'Anchoring failed'),
            ]),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _emptyState(_C C) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.touch_app_outlined,
                size: 32, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 14),
          Text('Select a record',
              style: TextStyle(color: C.txtPrimary,
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Click any record on the left\nto view blockchain details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.txtSecond,
                  fontSize: 13, height: 1.5)),
        ]));
  }

  // ════════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ════════════════════════════════════════════════════════════

  Widget _secTitle(_C C, String t, IconData i) {
    return Row(children: [
      Icon(i, size: 15, color: C.accent),
      const SizedBox(width: 7),
      Text(t, style: TextStyle(color: C.txtPrimary,
          fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _card(_C C, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.border)),
      child: Column(children: rows),
    );
  }

  Widget _row(_C C, String label, String value, {
    String? copy,
    bool mono = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: C.txtMuted, fontSize: 11))),
        Expanded(
          // SelectableText so value is always visible + selectable
          child: SelectableText(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                  color: valueColor ?? C.txtPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: mono ? 'monospace' : null)),
        ),
        if (copy != null && copy.isNotEmpty)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _copy(copy, label),
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Tooltip(
                    message: 'Copy full value',
                    child: Icon(Icons.copy_outlined,
                        size: 12, color: C.txtMuted)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _hashBox(_C C, String hash) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: C.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF059669).withOpacity(0.3))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fingerprint_rounded,
              size: 15, color: Color(0xFF059669)),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(hash,
                style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.6)),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _copy(hash, 'SHA-256 hash'),
              child: const Tooltip(
                  message: 'Copy hash',
                  child: Icon(Icons.copy_outlined,
                      size: 12, color: Color(0xFF059669))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(_C C, String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: C.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.border)),
      child: Text(msg,
          style: TextStyle(color: C.txtMuted, fontSize: 12)),
    );
  }

  Widget _checkRow(_C C, String title, bool done, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
                color: done
                    ? const Color(0xFF059669).withOpacity(0.12)
                    : C.inputBg,
                shape: BoxShape.circle,
                border: Border.all(
                    color: done
                        ? const Color(0xFF059669).withOpacity(0.4)
                        : C.border)),
            child: Icon(
                done ? Icons.check_rounded : Icons.hourglass_empty_rounded,
                size: 12,
                color: done ? const Color(0xFF059669) : C.txtMuted)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: C.txtPrimary,
                fontSize: 12, fontWeight: FontWeight.w600)),
            Text(sub, style: TextStyle(
                color: C.txtSecond, fontSize: 11)),
          ],
        )),
      ]),
    );
  }

  Widget _badge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(_cap(status),
          style: TextStyle(color: color,
              fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _outlineBtn(_C C, String label, IconData icon,
      VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
              border: Border.all(color: C.accent.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(9)),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: C.accent),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(
                    color: C.accent, fontSize: 12,
                    fontWeight: FontWeight.w600)),
              ]),
        ),
      ),
    );
  }

  Widget _miniBtn(_C C, String label, IconData icon,
      VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: C.inputBg,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: C.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: C.accent),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
                color: C.accent, fontSize: 11,
                fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerTile(_C C) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.border)),
      child: Row(children: [
        Container(width: 34, height: 34,
            decoration: BoxDecoration(
                color: C.inputBg,
                borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 11, color: C.inputBg),
            const SizedBox(height: 6),
            Container(height: 10, width: 120, color: C.inputBg),
          ],
        )),
      ]),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'anchored' => const Color(0xFF059669),
    'pending'  => const Color(0xFFD97706),
    'failed'   => const Color(0xFFEF4444),
    'all'      => const Color(0xFF2563EB),
    _          => const Color(0xFF94A3B8),
  };

  IconData _statusIcon(String s) => switch (s) {
    'anchored' => Icons.verified_rounded,
    'pending'  => Icons.hourglass_bottom_rounded,
    'failed'   => Icons.error_outline_rounded,
    _          => Icons.help_outline_rounded,
  };

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _timeAgo(String? raw) {
    if (raw == null) return '—';
    final t = DateTime.tryParse(raw);
    if (t == null) return '—';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1)  return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours   < 24) return '${d.inHours}h ago';
    if (d.inDays    < 7)  return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final t = DateTime.tryParse(raw);
    if (t == null) return raw;
    final l = t.toLocal();
    return '${l.day.toString().padLeft(2,'0')}/'
        '${l.month.toString().padLeft(2,'0')}/'
        '${l.year}  '
        '${l.hour.toString().padLeft(2,'0')}:'
        '${l.minute.toString().padLeft(2,'0')}';
  }

  String _fmtSize(dynamic b) {
    if (b == null) return '—';
    final n = b is int ? b : int.tryParse('$b') ?? 0;
    if (n < 1024)       return '$n B';
    if (n < 1048576)    return '${(n/1024).toStringAsFixed(1)} KB';
    if (n < 1073741824) return '${(n/1048576).toStringAsFixed(1)} MB';
    return '${(n/1073741824).toStringAsFixed(1)} GB';
  }
}

class _C {
  final bool isDark;
  _C(this.isDark);
  Color get bg         => isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF0F4FF);
  Color get card       => isDark ? const Color(0xFF111827) : Colors.white;
  Color get inputBg    => isDark ? const Color(0xFF1A2540) : const Color(0xFFF8FAFF);
  Color get border     => isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0);
  Color get txtPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get txtSecond  => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get txtMuted   => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
  Color get accent     => const Color(0xFF2563EB);
}