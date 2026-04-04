// upload_evidence_screen.dart
// Premium Glassmorphism UI — fully responsive (mobile + tablet + desktop)
// All original logic 100% preserved. UI transformed.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

// ── Breakpoints ───────────────────────────────────────────────
const double _kMobile = 600;
const double _kTablet = 1024;

// ── Design tokens ─────────────────────────────────────────────
const Color _kAccent    = Color(0xFF7C3AED);
const Color _kBlue      = Color(0xFF2563EB);
const Color _kGreen     = Color(0xFF059669);
const Color _kAmber     = Color(0xFFD97706);
const Color _kRed       = Color(0xFFEF4444);
const Color _kBgBase    = Color(0xFFEEF2FF);
const Color _kBorderIdle = Color(0xFFD1D5DB);

class UploadEvidenceScreen extends StatefulWidget {
  final String? preselectedCaseId;
  const UploadEvidenceScreen({super.key, this.preselectedCaseId});

  @override
  State<UploadEvidenceScreen> createState() => _UploadEvidenceScreenState();
}

class _UploadEvidenceScreenState extends State<UploadEvidenceScreen>
    with TickerProviderStateMixin {

  // ── Original state vars (all preserved) ──────────────────────
  final _api      = ApiService();
  final _descCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();

  List<dynamic> _cases          = [];
  String?       _selectedCaseId;
  bool          _casesLoading   = true;
  String?       _casesError;

  PlatformFile? _pickedFile;
  String?       _evidenceType   = 'document';

  bool    _isUploading     = false;
  double  _uploadProgress  = 0;
  bool    _uploaded        = false;
  Map<String, dynamic>? _uploadResult;
  String? _uploadError;

  // ── Animations ────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double>   _opacity;
  late Animation<Offset>   _slide;
  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  // Hover states for drop zone
  bool _dropHovered = false;

  static const _evidenceTypes = [
    {'value': 'image',    'label': 'Image',    'icon': Icons.image_outlined,       'color': 0xFF2563EB},
    {'value': 'video',    'label': 'Video',    'icon': Icons.videocam_outlined,    'color': 0xFF7C3AED},
    {'value': 'audio',    'label': 'Audio',    'icon': Icons.mic_outlined,         'color': 0xFF059669},
    {'value': 'document', 'label': 'Document', 'icon': Icons.description_outlined, 'color': 0xFFD97706},
    {'value': 'other',    'label': 'Other',    'icon': Icons.attach_file_rounded,  'color': 0xFF64748B},
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _opacity = _entryCtrl.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: const Interval(0, 0.65))));
    _slide   = _entryCtrl.drive(Tween(begin: const Offset(0, 0.04), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)));
    _entryCtrl.forward();

    _bgCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _bgAnim  = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _pulse     = _pulseCtrl.drive(Tween(begin: 0.95, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)));

    _loadCases();
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _bgCtrl.dispose(); _pulseCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── All original logic (preserved exactly) ────────────────────
  Future<void> _loadCases() async {
    setState(() { _casesLoading = true; _casesError = null; });
    try {
      final cases = await _api.getAllCases();
      if (mounted) setState(() {
        _cases = cases;
        _casesLoading = false;
        if (widget.preselectedCaseId != null) {
          _selectedCaseId = widget.preselectedCaseId;
        } else if (cases.isNotEmpty) {
          _selectedCaseId = cases.first['_id'];
        }
      });
    } catch (e) {
      if (mounted) setState(() {
        _casesError   = 'Failed to load cases. Check connection.';
        _casesLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.any, withData: true, allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      setState(() {
        _pickedFile   = f;
        _uploadError  = null;
        _uploaded     = false;
        _uploadResult = null;
        _evidenceType = _detectType(f.extension ?? '');
      });
    }
  }

  String _detectType(String ext) {
    final e = ext.toLowerCase();
    if (['jpg','jpeg','png','gif','bmp','webp','heic'].contains(e)) return 'image';
    if (['mp4','mov','avi','mkv','wmv','flv'].contains(e))          return 'video';
    if (['mp3','wav','aac','m4a','ogg','flac'].contains(e))         return 'audio';
    if (['pdf','doc','docx','xls','xlsx','txt','csv','ppt','pptx'].contains(e)) return 'document';
    return 'other';
  }

  Future<void> _upload() async {
    if (_pickedFile == null || _selectedCaseId == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isUploading = true; _uploadError = null; _uploadProgress = 0; });
    _simulateProgress();
    try {
      final bytes    = _pickedFile!.bytes;
      final fileName = _pickedFile!.name;
      if (bytes == null) {
        setState(() { _isUploading = false; _uploadError = 'Could not read file bytes. Please try again.'; });
        return;
      }
      final result = await _api.uploadEvidenceBytes(
        bytes, fileName, _selectedCaseId!,
        description:  _descCtrl.text.trim(),
        evidenceType: _evidenceType ?? 'document',
        mimeType:     _getMimeType(_pickedFile!.extension ?? ''),
      );
      if (mounted) setState(() {
        _isUploading    = false;
        _uploadProgress = 1.0;
        _uploaded       = true;
        _uploadResult   = result;
      });
    } catch (e) {
      if (mounted) setState(() { _isUploading = false; _uploadError = 'Upload failed: ${e.toString()}'; });
    }
  }

  void _simulateProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_isUploading) return false;
      setState(() { if (_uploadProgress < 0.85) _uploadProgress += 0.06; });
      return _isUploading;
    });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgBase,
      body: Stack(children: [
        Positioned.fill(child: _AnimBg(anim: _bgAnim)),
        SafeArea(child: FadeTransition(opacity: _opacity,
            child: SlideTransition(position: _slide,
                child: Column(children: [
                  _buildAppBar(),
                  Expanded(child: _uploaded ? _successBody() : _formBody()),
                ])))),
      ]),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.70),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
        child: Row(children: [
          _ABBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          Container(width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [_kAccent, Color(0xFF4F46E5)])),
              child: const Icon(Icons.upload_file_outlined, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Text('Upload Evidence',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          const Spacer(),
          // Network badge
          AnimatedBuilder(animation: _pulse, builder: (_, __) =>
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _kGreen.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kGreen.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Transform.scale(scale: _pulse.value,
                        child: Container(width: 6, height: 6,
                            decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle))),
                    const SizedBox(width: 5),
                    const Text('Firebase', style: TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                  ]))),
          const SizedBox(width: 8),
        ]),
      ),
    ));
  }

  // ── Responsive form body ──────────────────────────────────────
  Widget _formBody() {
    return LayoutBuilder(builder: (_, constraints) {
      final w        = constraints.maxWidth;
      final isMobile = w < _kMobile;
      final isTablet = w >= _kMobile && w < _kTablet;

      if (isMobile) {
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
            child: Form(key: _formKey, child: Column(children: [
              _step1CaseSelector(),
              const SizedBox(height: 14),
              _step2FileDropZone(),
              const SizedBox(height: 14),
              _step3Details(),
              const SizedBox(height: 14),
              if (_isUploading) ...[_progressCard(), const SizedBox(height: 12)],
              if (_uploadError != null) ...[_errorCard(), const SizedBox(height: 12)],
              _uploadButton(),
              const SizedBox(height: 8),
              Center(child: TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)))),
            ])));
      }

      if (isTablet) {
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Form(key: _formKey, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: Column(children: [
                _step1CaseSelector(),
                const SizedBox(height: 14),
                _step2FileDropZone(),
                const SizedBox(height: 14),
                _step3Details(),
                const SizedBox(height: 14),
                if (_isUploading) ...[_progressCard(), const SizedBox(height: 12)],
                if (_uploadError != null) ...[_errorCard(), const SizedBox(height: 12)],
                _uploadButton(),
              ])),
              const SizedBox(width: 16),
              SizedBox(width: 230, child: Column(children: [
                _fileInfoPanel(),
                const SizedBox(height: 14),
                _blockchainPanel(),
              ])),
            ])));
      }

      // Desktop
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
            child: Form(key: _formKey, child: Column(children: [
              _step1CaseSelector(),
              const SizedBox(height: 18),
              _step2FileDropZone(),
              const SizedBox(height: 18),
              _step3Details(),
              const SizedBox(height: 18),
              if (_isUploading) ...[_progressCard(), const SizedBox(height: 14)],
              if (_uploadError != null) ...[_errorCard(), const SizedBox(height: 14)],
              _uploadButton(),
              const SizedBox(height: 10),
              Center(child: TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)))),
            ])))),
        Container(width: 1, color: Colors.white.withOpacity(0.5)),
        SizedBox(width: 290, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 24, 20, 40),
            child: Column(children: [
              _fileInfoPanel(),
              const SizedBox(height: 16),
              _storagePanel(),
              const SizedBox(height: 16),
              _blockchainPanel(),
            ]))),
      ]);
    });
  }

  // ── Step 1: Case Selector ─────────────────────────────────────
  Widget _step1CaseSelector() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepHeader(num: '1', label: 'Select Case', icon: Icons.folder_open_outlined, color: _kBlue),
          const SizedBox(height: 16),
          _buildCaseDropdown(),
        ])));
  }

  Widget _buildCaseDropdown() {
    if (_casesLoading) {
      return Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorderIdle, width: 1.2)),
          child: Row(children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2)),
            const SizedBox(width: 12),
            const Text('Loading cases...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          ]));
    }
    if (_casesError != null) {
      return Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA))),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: _kRed, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_casesError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
            GestureDetector(onTap: _loadCases,
                child: const Text('Retry', style: TextStyle(color: _kBlue, fontSize: 12, fontWeight: FontWeight.w600))),
          ]));
    }
    if (_cases.isEmpty) {
      return Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorderIdle, width: 1.2)),
          child: Row(children: [
            const Icon(Icons.folder_off_outlined, size: 18, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 10),
            const Text('No cases found. Create a case first.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ]));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorderIdle, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _selectedCaseId, isExpanded: true,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF9CA3AF)),
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
        items: _cases.map<DropdownMenuItem<String>>((c) {
          final id     = c['_id'] as String;
          final title  = c['title'] as String? ?? 'Untitled';
          final ref    = c['caseRef'] as String? ?? '';
          final status = c['status'] as String? ?? 'open';
          return DropdownMenuItem<String>(value: id,
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle,
                        color: status == 'open' ? _kGreen : const Color(0xFF9CA3AF))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(title, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
                      if (ref.isNotEmpty)
                        Text(ref, style: const TextStyle(color: _kBlue, fontSize: 10, fontFamily: 'monospace')),
                    ])),
                  ])));
          }).toList(),
        onChanged: (v) { if (v != null) setState(() => _selectedCaseId = v); },
      )),
    );
  }

  // ── Step 2: File Drop Zone ─────────────────────────────────────
  Widget _step2FileDropZone() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepHeader(num: '2', label: 'Choose File', icon: Icons.attach_file_rounded, color: _kAccent),
          const SizedBox(height: 16),
          _pickedFile != null ? _selectedFileTile() : _dropZone(),
        ])));
  }

  Widget _dropZone() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _dropHovered = true),
      onExit:  (_) => setState(() => _dropHovered = false),
      child: GestureDetector(onTap: _pickFile,
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: _dropHovered ? _kAccent.withOpacity(0.06) : Colors.white.withOpacity(0.40),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _dropHovered ? _kAccent.withOpacity(0.45) : _kBorderIdle,
              width: 1.8,
              // dashed via decoration:
            ),
            boxShadow: _dropHovered
                ? [BoxShadow(color: _kAccent.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 64, height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: _dropHovered ? _kAccent.withOpacity(0.15) : _kAccent.withOpacity(0.08)),
                child: Icon(Icons.cloud_upload_outlined, size: 30,
                    color: _dropHovered ? _kAccent : _kAccent.withOpacity(0.7))),
            const SizedBox(height: 16),
            Text('Click to select a file',
                style: TextStyle(color: const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700,
                    letterSpacing: _dropHovered ? -0.2 : 0)),
            const SizedBox(height: 5),
            const Text('Images · Videos · Audio · Documents · PDFs\nMax size: 100MB',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, height: 1.5)),
            const SizedBox(height: 18),
            AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _dropHovered
                      ? const LinearGradient(colors: [_kAccent, Color(0xFF4F46E5)])
                      : null,
                  color: _dropHovered ? null : _kAccent.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kAccent.withOpacity(0.3)),
                ),
                child: Text('Browse Files',
                    style: TextStyle(
                        color: _dropHovered ? Colors.white : _kAccent,
                        fontSize: 13, fontWeight: FontWeight.w700))),
          ]),
        ),
      ),
    );
  }

  Widget _selectedFileTile() {
    final f          = _pickedFile!;
    final typeColor  = _typeColor(_evidenceType ?? 'document');
    final typeIcon   = _typeIcon(_evidenceType ?? 'document');
    return AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: typeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: typeColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(width: 50, height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [typeColor, typeColor.withOpacity(0.7)]),
              boxShadow: [BoxShadow(color: typeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Icon(typeIcon, size: 24, color: Colors.white)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.name, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                child: Text((f.extension ?? 'file').toUpperCase(),
                    style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Text(_formatSize(f.size), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
          ]),
        ])),
        const SizedBox(width: 8),
        _iconAction(Icons.edit_outlined,         _kBlue,   _pickFile),
        const SizedBox(width: 6),
        _iconAction(Icons.close_rounded,          _kRed,    () => setState(() { _pickedFile = null; _uploadError = null; })),
      ]),
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
          child: Container(width: 32, height: 32,
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.2))),
              child: Icon(icon, size: 15, color: color)));

  // ── Step 3: Details ───────────────────────────────────────────
  Widget _step3Details() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepHeader(num: '3', label: 'Evidence Details', icon: Icons.info_outline_rounded, color: _kGreen),
          const SizedBox(height: 16),

          const _FL(label: 'Evidence Type'),
          const SizedBox(height: 10),
          _typeSelector(),
          const SizedBox(height: 16),

          const _FL(label: 'Description (optional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descCtrl, maxLines: 3,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe this evidence — chain of custody context, scene notes...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              filled: true, fillColor: Colors.white.withOpacity(0.65),
              contentPadding: const EdgeInsets.all(14),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kAccent, width: 2.0)),
              errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
            ),
          ),
        ])));
  }

  Widget _typeSelector() {
    return Wrap(spacing: 8, runSpacing: 8,
      children: _evidenceTypes.map((t) {
        final active = _evidenceType == t['value'];
        final color  = Color(t['color'] as int);
        return GestureDetector(
          onTap: () => setState(() => _evidenceType = t['value'] as String),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: active ? LinearGradient(colors: [color, color.withOpacity(0.75)]) : null,
              color: active ? null : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? color : _kBorderIdle, width: active ? 1.5 : 1.2),
              boxShadow: active ? [BoxShadow(color: color.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 3))] : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t['icon'] as IconData, size: 15, color: active ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 7),
              Text(t['label'] as String, style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF475569),
                  fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Progress Card ─────────────────────────────────────────────
  Widget _progressCard() {
    final pct = (_uploadProgress * 100).toInt();
    final phase = pct < 60 ? 'Uploading file to Firebase Storage...'
        : pct < 85 ? 'Saving metadata to MongoDB...'
        : 'Anchoring hash on Polygon blockchain...';
    return _GlassCard(tint: const Color(0xFFF5F3FF), child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(value: _uploadProgress, color: _kAccent, strokeWidth: 2.5)),
            const SizedBox(width: 12),
            Expanded(child: Text(phase, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600))),
            Text('$pct%', style: const TextStyle(color: _kAccent, fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: _uploadProgress, minHeight: 7,
                  backgroundColor: _kAccent.withOpacity(0.10),
                  valueColor: const AlwaysStoppedAnimation(_kAccent))),
          const SizedBox(height: 8),
          // Step indicators
          Row(children: [
            _stepDot(pct >= 1,  pct >= 1  && pct < 60, 'Upload'),
            _stepLine(pct >= 60),
            _stepDot(pct >= 60, pct >= 60 && pct < 85, 'Save'),
            _stepLine(pct >= 85),
            _stepDot(pct >= 85, pct >= 85, 'Blockchain'),
          ]),
        ])));
  }

  Widget _stepDot(bool done, bool active, String label) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(duration: const Duration(milliseconds: 300),
            width: 14, height: 14,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: done ? _kAccent : Colors.white,
              border: Border.all(color: done ? _kAccent : _kBorderIdle, width: 1.5),
              boxShadow: active ? [BoxShadow(color: _kAccent.withOpacity(0.4), blurRadius: 6, spreadRadius: 2)] : [],
            ),
            child: done ? const Icon(Icons.check, size: 8, color: Colors.white) : null),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: done ? _kAccent : const Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.w600)),
      ]);

  Widget _stepLine(bool done) => Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
          color: done ? _kAccent : _kBorderIdle)));

  // ── Error Card ────────────────────────────────────────────────
  Widget _errorCard() {
    return _GlassCard(tint: const Color(0xFFFEF2F2), child: Padding(padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: _kRed.withOpacity(0.1)),
              child: const Icon(Icons.error_outline_rounded, color: _kRed, size: 17)),
          const SizedBox(width: 10),
          Expanded(child: Text(_uploadError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
          GestureDetector(onTap: () => setState(() => _uploadError = null),
              child: const Icon(Icons.close_rounded, color: _kRed, size: 16)),
        ])));
  }

  // ── Upload Button ─────────────────────────────────────────────
  Widget _uploadButton() {
    final canUpload = _pickedFile != null && _selectedCaseId != null && !_isUploading;
    return Container(width: double.infinity, height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: canUpload ? const LinearGradient(colors: [_kAccent, Color(0xFF4F46E5)]) : null,
        color: canUpload ? null : _kAccent.withOpacity(0.35),
        boxShadow: canUpload ? [BoxShadow(color: _kAccent.withOpacity(0.38), blurRadius: 18, offset: const Offset(0, 6))] : [],
      ),
      child: Material(color: Colors.transparent,
        child: InkWell(onTap: canUpload ? _upload : null, borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.15),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(_isUploading ? 'Uploading...' : _pickedFile == null ? 'Select a file first' : 'Upload Evidence',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ])),
        ),
      ),
    );
  }

  // ── Right Panel: File Info ────────────────────────────────────
  Widget _fileInfoPanel() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PanelHeader(icon: Icons.insert_drive_file_outlined, label: 'Selected File', color: _kAccent),
          const SizedBox(height: 14),
          if (_pickedFile == null)
            Center(child: Column(children: [
              Container(width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _kAccent.withOpacity(0.06)),
                  child: Icon(Icons.cloud_upload_outlined, size: 24, color: _kAccent.withOpacity(0.5))),
              const SizedBox(height: 8),
              const Text('No file selected', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            ]))
          else ...[
            Row(children: [
              Container(width: 38, height: 38,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                    color: _typeColor(_evidenceType ?? 'document'),),
                  child: Icon(_typeIcon(_evidenceType ?? 'document'), size: 20, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(child: Text(_pickedFile!.name, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 12),
            _detailRow('Size',     _formatSize(_pickedFile!.size)),
            _detailRow('Format',   (_pickedFile!.extension ?? '—').toUpperCase()),
            _detailRow('Category', (_evidenceType ?? '—').toUpperCase()),
          ],
        ])));
  }

  Widget _detailRow(String k, String v) => Padding(padding: const EdgeInsets.only(bottom: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
        Text(v, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w600)),
      ]));

  // ── Right Panel: Storage ──────────────────────────────────────
  Widget _storagePanel() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PanelHeader(icon: Icons.cloud_outlined, label: 'Storage Path', color: _kAccent),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _kAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kAccent.withOpacity(0.15))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _pathLine('evidence/'),
                _pathLine('  {caseId}/'),
                _pathLine('    {ts}_{uuid}.ext'),
              ])),
          const SizedBox(height: 8),
          const Text('Files organised by case ID in Firebase Storage.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, height: 1.5)),
        ])));
  }

  Widget _pathLine(String text) => Padding(padding: const EdgeInsets.only(bottom: 3),
      child: Text(text, style: const TextStyle(color: _kAccent, fontSize: 11, fontFamily: 'monospace')));

  // ── Right Panel: Blockchain ────────────────────────────────────
  Widget _blockchainPanel() {
    return _GlassCard(tint: const Color(0xFFF5F3FF), child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PanelHeader(icon: Icons.link_rounded, label: 'Blockchain Process', color: _kAccent),
          const SizedBox(height: 12),
          ...[
            ['1', 'SHA-256 hash generated from file bytes'],
            ['2', 'File uploaded to Firebase Storage'],
            ['3', 'Metadata saved to MongoDB'],
            ['4', 'Hash anchored on Polygon Amoy'],
          ].map((s) => Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 18, height: 18,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [_kAccent, Color(0xFF4F46E5)])),
                    child: Center(child: Text(s[0], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 9),
                Expanded(child: Text(s[1], style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.45))),
              ]))),
        ])));
  }

  // ── Success Body ───────────────────────────────────────────────
  Widget _successBody() {
    final res = _uploadResult ?? {};
    final f   = _pickedFile;
    return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
            child: _GlassCard(child: Padding(padding: const EdgeInsets.all(36),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Animated check
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700), curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(width: 88, height: 88,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [_kGreen, Color(0xFF0D9488)]),
                            boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))]),
                        child: const Icon(Icons.check_rounded, size: 44, color: Colors.white)),
                  ),
                  const SizedBox(height: 22),
                  const Text('Evidence Uploaded!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 10),
                  const Text('Your file has been uploaded to Firebase Storage\nand is being anchored on the Polygon blockchain.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.6)),
                  const SizedBox(height: 22),
                  // Result card
                  _GlassCard(tint: const Color(0xFFF5F3FF), child: Padding(padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _resultRow(Icons.insert_drive_file_outlined, 'File',         f?.name ?? '—',           _kAccent),
                        const SizedBox(height: 10),
                        _resultRow(Icons.tag_rounded,                'Evidence ID',  res['evidenceId'] ?? '—',  _kBlue),
                        const SizedBox(height: 10),
                        _resultRow(Icons.fingerprint_rounded,        'SHA-256',      _shortHash(res['fileHash'] ?? ''), _kGreen),
                        const SizedBox(height: 10),
                        _resultRow(Icons.link_rounded,               'Blockchain',   'Pending — anchoring…',   _kAmber),
                      ]))),
                  const SizedBox(height: 26),
                  Row(children: [
                    Expanded(child: _OutlineBtn(label: 'Upload Another', icon: Icons.add_rounded,
                        onTap: () => setState(() {
                          _uploaded = false; _uploadResult = null;
                          _pickedFile = null; _descCtrl.clear(); _uploadProgress = 0;
                        }))),
                    const SizedBox(width: 12),
                    Expanded(child: _GradBtn(label: 'Dashboard', icon: Icons.dashboard_outlined,
                        onTap: () => Navigator.pop(context))),
                  ]),
                ])))))));
  }

  Widget _resultRow(IconData icon, String label, String value, Color color) =>
      Row(children: [
        Container(width: 28, height: 28,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.1)),
            child: Icon(icon, size: 14, color: color)),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(child: SelectableText(value,
            style: TextStyle(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600,
                fontFamily: value.length > 20 ? 'monospace' : null))),
      ]);

  // ── Helpers ────────────────────────────────────────────────────
  String _formatSize(int bytes) {
    if (bytes < 1024)       return '$bytes B';
    if (bytes < 1048576)    return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  String _shortHash(String hash) {
    if (hash.length < 16) return hash;
    return '${hash.substring(0, 8)}…${hash.substring(hash.length - 8)}';
  }

  Color _typeColor(String type) => switch (type) {
    'image'    => _kBlue,
    'video'    => _kAccent,
    'audio'    => _kGreen,
    'document' => _kAmber,
    _          => const Color(0xFF64748B),
  };

  IconData _typeIcon(String type) => switch (type) {
    'image'    => Icons.image_outlined,
    'video'    => Icons.videocam_outlined,
    'audio'    => Icons.mic_outlined,
    'document' => Icons.description_outlined,
    _          => Icons.attach_file_rounded,
  };
}

// ── MIME helper (outside class, same as original) ─────────────
String _getMimeType(String ext) {
  switch (ext.toLowerCase()) {
    case 'jpg': case 'jpeg': return 'image/jpeg';
    case 'png':  return 'image/png';
    case 'gif':  return 'image/gif';
    case 'webp': return 'image/webp';
    case 'mp4':  return 'video/mp4';
    case 'mov':  return 'video/quicktime';
    case 'avi':  return 'video/x-msvideo';
    case 'mp3':  return 'audio/mpeg';
    case 'wav':  return 'audio/wav';
    case 'pdf':  return 'application/pdf';
    case 'doc':  return 'application/msword';
    case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'txt':  return 'text/plain';
    case 'csv':  return 'text/csv';
    default:     return 'application/octet-stream';
  }
}

// ─────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────

class _AnimBg extends StatelessWidget {
  final Animation<double> anim;
  const _AnimBg({required this.anim});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: anim, builder: (_, __) {
    final t = anim.value;
    return Container(color: _kBgBase, child: Stack(children: [
      Positioned(left: -120 + t * 70, top: -90 + t * 50, child: _orb(320, _kAccent,   0.12)),
      Positioned(right: -80 + t * 40, bottom: 30 + t * 80, child: _orb(260, _kBlue,   0.09)),
      Positioned(left: MediaQuery.of(context).size.width * 0.4,
          top: MediaQuery.of(context).size.height * 0.3 - t * 50,
          child: _orb(190, const Color(0xFF059669), 0.07)),
    ]));
  });
  Widget _orb(double sz, Color c, double op) => Container(width: sz, height: sz,
      decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c.withOpacity(op), c.withOpacity(0)])));
}

class _GlassCard extends StatelessWidget {
  final Widget child; final Color? tint;
  const _GlassCard({required this.child, this.tint});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _kAccent.withOpacity(0.07), blurRadius: 22, offset: const Offset(0, 7), spreadRadius: -2),
            BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 1, offset: const Offset(0, -1))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.3),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [(tint ?? Colors.white).withOpacity(0.90), (tint ?? Colors.white).withOpacity(0.58)])),
                  child: child))));
}

class _StepHeader extends StatelessWidget {
  final String num, label; final IconData icon; final Color color;
  const _StepHeader({required this.num, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 30, height: 30,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(colors: [color, color.withOpacity(0.75)])),
        child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)))),
    const SizedBox(width: 10),
    Icon(icon, size: 16, color: color),
    const SizedBox(width: 7),
    Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
    const SizedBox(width: 12),
    Expanded(child: Container(height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.35), Colors.transparent])))),
  ]);
}

class _FL extends StatelessWidget {
  final String label;
  const _FL({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1));
}

class _PanelHeader extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _PanelHeader({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 28, height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.08)),
        child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 9),
    Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}

class _GradBtn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _GradBtn({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(height: 46,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [_kAccent, Color(0xFF4F46E5)]),
          boxShadow: [BoxShadow(color: _kAccent.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))]),
      child: Material(color: Colors.transparent,
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ]))));
}

class _OutlineBtn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(height: 46,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.65),
          border: Border.all(color: _kAccent.withOpacity(0.35), width: 1.5)),
      child: Material(color: Colors.transparent,
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 16, color: _kAccent), const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: _kAccent, fontSize: 13, fontWeight: FontWeight.w700)),
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
              width: 38, height: 38,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  color: _h ? _kAccent.withOpacity(0.08) : Colors.transparent,
                  border: Border.all(color: _h ? _kAccent.withOpacity(0.2) : Colors.transparent)),
              child: Icon(widget.icon, size: 20, color: _h ? _kAccent : const Color(0xFF475569)))));
}