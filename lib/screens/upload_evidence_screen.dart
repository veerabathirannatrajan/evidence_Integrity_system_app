import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class UploadEvidenceScreen extends StatefulWidget {
  /// Pass a caseId to pre-select the case (from evidence list page).
  final String? preselectedCaseId;
  const UploadEvidenceScreen({super.key, this.preselectedCaseId});

  @override
  State<UploadEvidenceScreen> createState() => _UploadEvidenceScreenState();
}

class _UploadEvidenceScreenState extends State<UploadEvidenceScreen>
    with SingleTickerProviderStateMixin {

  final _api         = ApiService();
  final _descCtrl    = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  // ── Case selector ────────────────────────────────────────────
  List<dynamic> _cases         = [];
  String?       _selectedCaseId;
  bool          _casesLoading  = true;
  String?       _casesError;

  // ── File state ───────────────────────────────────────────────
  PlatformFile? _pickedFile;
  String?       _evidenceType  = 'document';

  // ── Upload state ─────────────────────────────────────────────
  bool    _isUploading    = false;
  double  _uploadProgress = 0;
  bool    _uploaded       = false;
  Map<String, dynamic>? _uploadResult;
  String? _uploadError;

  // ── Animation ────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double>   _opacity;
  late Animation<Offset>   _slide;

  final _evidenceTypes = const [
    {'value': 'image',    'label': 'Image',    'icon': Icons.image_outlined,        'color': 0xFF2563EB},
    {'value': 'video',    'label': 'Video',    'icon': Icons.videocam_outlined,     'color': 0xFF7C3AED},
    {'value': 'audio',    'label': 'Audio',    'icon': Icons.mic_outlined,          'color': 0xFF059669},
    {'value': 'document', 'label': 'Document', 'icon': Icons.description_outlined,  'color': 0xFFD97706},
    {'value': 'other',    'label': 'Other',    'icon': Icons.attach_file_rounded,   'color': 0xFF64748B},
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = _entryCtrl.drive(Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: const Interval(0, 0.6))));
    _slide = _entryCtrl.drive(
        Tween(begin: const Offset(0, 0.03), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)));
    _entryCtrl.forward();

    _loadCases();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Load cases from API ──────────────────────────────────────
  Future<void> _loadCases() async {
    setState(() { _casesLoading = true; _casesError = null; });
    try {
      final cases = await _api.getAllCases();
      if (mounted) {
        setState(() {
          _cases = cases;
          _casesLoading = false;
          // Pre-select if provided
          if (widget.preselectedCaseId != null) {
            _selectedCaseId = widget.preselectedCaseId;
          } else if (cases.isNotEmpty) {
            _selectedCaseId = cases.first['_id'];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _casesError   = 'Failed to load cases. Check connection.';
        _casesLoading = false;
      });
    }
  }

  // ── Pick file ────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,       // load bytes into memory
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      setState(() {
        _pickedFile    = f;
        _uploadError   = null;
        _uploaded      = false;
        _uploadResult  = null;
        // Auto-detect type
        _evidenceType  = _detectType(f.extension ?? '');
      });
    }
  }

  String _detectType(String ext) {
    final e = ext.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic']
        .contains(e)) return 'image';
    if (['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv']
        .contains(e)) return 'video';
    if (['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac']
        .contains(e)) return 'audio';
    if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv', 'ppt', 'pptx']
        .contains(e)) return 'document';
    return 'other';
  }

  // ── Upload ───────────────────────────────────────────────────
  Future<void> _upload() async {
    if (_pickedFile == null) return;
    if (_selectedCaseId == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading   = true;
      _uploadError   = null;
      _uploadProgress = 0;
    });

    // Simulate progress (real progress needs streaming HTTP)
    _simulateProgress();

    try {
      // Use bytes directly — works on Windows, Web, and Mobile
      // File(path) fails on Windows/Web because path is unavailable
      final bytes    = _pickedFile!.bytes;
      final fileName = _pickedFile!.name;

      if (bytes == null) {
        setState(() {
          _isUploading = false;
          _uploadError = 'Could not read file bytes. Please try again.';
        });
        return;
      }

      final result = await _api.uploadEvidenceBytes(
        bytes,
        fileName,
        _selectedCaseId!,
        description:  _descCtrl.text.trim(),
        evidenceType: _evidenceType ?? 'document',
        mimeType:     _getMimeType(_pickedFile!.extension ?? ''),
      );

      if (mounted) {
        setState(() {
          _isUploading    = false;
          _uploadProgress = 1.0;
          _uploaded       = true;
          _uploadResult   = result;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _isUploading  = false;
        _uploadError  = 'Upload failed: ${e.toString()}';
      });
    }
  }

  void _simulateProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_isUploading) return false;
      setState(() {
        if (_uploadProgress < 0.85) {
          _uploadProgress += 0.06;
        }
      });
      return _isUploading;
    });
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final C      = _C(isDark);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildAppBar(C),
      body: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: _uploaded ? _successBody(C) : _formBody(C),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────
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
          child: const Icon(Icons.upload_file_outlined,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text('Upload Evidence',
            style: TextStyle(color: C.txtPrimary,
                fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: C.border, height: 1)),
    );
  }

  // ════════════════════════════════════════════════════════════
  // FORM BODY
  // ════════════════════════════════════════════════════════════
  Widget _formBody(_C C) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Left: main form ───────────────────────────────
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Step 1: Select Case ────────────────
                  _stepHeader(C, '1', 'Select Case',
                      Icons.folder_outlined,
                      const Color(0xFF2563EB)),
                  const SizedBox(height: 14),
                  _caseSelector(C),

                  const SizedBox(height: 26),

                  // ── Step 2: Choose File ────────────────
                  _stepHeader(C, '2', 'Choose File',
                      Icons.attach_file_rounded,
                      const Color(0xFF7C3AED)),
                  const SizedBox(height: 14),
                  _fileDropZone(C),

                  const SizedBox(height: 26),

                  // ── Step 3: Evidence Details ───────────
                  _stepHeader(C, '3', 'Evidence Details',
                      Icons.info_outline_rounded,
                      const Color(0xFF059669)),
                  const SizedBox(height: 14),

                  // Evidence type
                  _label(C, 'Evidence Type'),
                  const SizedBox(height: 10),
                  _typeSelector(C),

                  const SizedBox(height: 16),

                  // Description
                  _label(C, 'Description (optional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    style: TextStyle(
                        color: C.txtPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                      'Describe this evidence...',
                      hintStyle: TextStyle(
                          color: C.txtMuted, fontSize: 14),
                      filled: true,
                      fillColor: C.inputBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(color: C.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(color: C.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(
                              color: C.accent, width: 1.5)),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Upload progress ────────────────────
                  if (_isUploading) ...[
                    _progressBar(C),
                    const SizedBox(height: 20),
                  ],

                  // ── Error ──────────────────────────────
                  if (_uploadError != null) ...[
                    _errorBanner(C),
                    const SizedBox(height: 16),
                  ],

                  // ── Upload button ──────────────────────
                  _uploadBtn(C),

                ],
              ),
            ),
          ),
        ),

        // ── Right: info panel ──────────────────────────────
        SizedBox(
          width: 270,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 28, 28, 28),
            child: Column(children: [
              _selectedFileCard(C),
              const SizedBox(height: 16),
              _storageInfoCard(C),
              const SizedBox(height: 16),
              _blockchainInfoCard(C),
            ]),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // WIDGETS
  // ════════════════════════════════════════════════════════════

  Widget _stepHeader(_C C, String num, String title,
      IconData icon, Color color) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8)),
        child: Center(
          child: Text(num,
              style: const TextStyle(color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(width: 10),
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 7),
      Text(title,
          style: TextStyle(color: C.txtPrimary,
              fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(width: 12),
      Expanded(child: Divider(color: C.border)),
    ]);
  }

  Widget _label(_C C, String text) {
    return Text(text,
        style: TextStyle(color: C.txtSecond,
            fontSize: 12, fontWeight: FontWeight.w500));
  }

  // ── Case selector dropdown ───────────────────────────────────
  Widget _caseSelector(_C C) {
    if (_casesLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
            color: C.inputBg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: C.border)),
        child: Row(children: [
          const SizedBox(width: 14),
          SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(
                  color: C.accent, strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('Loading cases...',
              style: TextStyle(color: C.txtMuted, fontSize: 14)),
        ]),
      );
    }

    if (_casesError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFFECACA))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 15),
          const SizedBox(width: 8),
          Expanded(child: Text(_casesError!,
              style: const TextStyle(
                  color: Color(0xFFDC2626), fontSize: 13))),
          GestureDetector(
              onTap: _loadCases,
              child: Text('Retry',
                  style: TextStyle(color: C.accent,
                      fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      );
    }

    if (_cases.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: C.inputBg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: C.border)),
        child: Row(children: [
          Icon(Icons.folder_off_outlined,
              size: 18, color: C.txtMuted),
          const SizedBox(width: 10),
          Text('No cases found. Create a case first.',
              style: TextStyle(color: C.txtSecond, fontSize: 13)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: C.inputBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: C.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCaseId,
          isExpanded: true,
          dropdownColor: C.card,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: C.txtMuted),
          style: TextStyle(color: C.txtPrimary, fontSize: 14),
          items: _cases.map<DropdownMenuItem<String>>((c) {
            final id     = c['_id'] as String;
            final title  = c['title'] as String? ?? 'Untitled';
            final ref    = c['caseRef'] as String? ?? '';
            final status = c['status'] as String? ?? 'open';

            return DropdownMenuItem<String>(
              value: id,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status == 'open'
                            ? const Color(0xFF059669)
                            : const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: C.txtPrimary, fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (ref.isNotEmpty)
                          Text(ref,
                              style: TextStyle(
                                  color: C.accent, fontSize: 10,
                                  fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedCaseId = v);
          },
        ),
      ),
    );
  }

  // ── File drop zone ───────────────────────────────────────────
  Widget _fileDropZone(_C C) {
    if (_pickedFile != null) {
      return _selectedFileTile(C);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _pickFile,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(
            color: C.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: C.border,
              width: 1.5,
              // dashed look via decoration
            ),
          ),
          child: Column(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.cloud_upload_outlined,
                  size: 28, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 14),
            Text('Click to select a file',
                style: TextStyle(color: C.txtPrimary,
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                'Images, Videos, Audio, Documents, PDFs\n'
                    'Max size: 100MB',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.txtMuted, fontSize: 12,
                    height: 1.5)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Browse Files',
                  style: TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Selected file tile ───────────────────────────────────────
  Widget _selectedFileTile(_C C) {
    final f        = _pickedFile!;
    final sizeText = _formatSize(f.size);
    final typeColor = _typeColor(_evidenceType ?? 'document');
    final typeIcon  = _typeIcon(_evidenceType ?? 'document');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: C.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: typeColor.withOpacity(0.4),
              width: 1.5)),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(typeIcon, size: 24, color: typeColor),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: C.txtPrimary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Row(children: [
              Text(sizeText,
                  style: TextStyle(color: C.txtSecond, fontSize: 11)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                    (f.extension ?? 'file').toUpperCase(),
                    style: TextStyle(color: typeColor,
                        fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
          ],
        )),
        // Remove file
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() {
              _pickedFile   = null;
              _uploadError  = null;
            }),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close_rounded,
                  size: 15, color: Color(0xFFEF4444)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Change file
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: C.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.edit_outlined,
                  size: 15, color: C.accent),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Evidence type selector ───────────────────────────────────
  Widget _typeSelector(_C C) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: _evidenceTypes.map((t) {
        final active = _evidenceType == t['value'];
        final color  = Color(t['color'] as int);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(
                    () => _evidenceType = t['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: active
                    ? color.withOpacity(0.12)
                    : C.inputBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active ? color : C.border,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t['icon'] as IconData, size: 15,
                      color: active ? color : C.txtSecond),
                  const SizedBox(width: 7),
                  Text(t['label'] as String,
                      style: TextStyle(
                          color: active ? color : C.txtSecond,
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Upload progress bar ──────────────────────────────────────
  Widget _progressBar(_C C) {
    final pct = (_uploadProgress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Uploading to Firebase Storage...',
                style: TextStyle(color: C.txtSecond,
                    fontSize: 12, fontWeight: FontWeight.w500)),
            Text('$pct%',
                style: TextStyle(color: C.accent,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _uploadProgress,
            minHeight: 6,
            backgroundColor: C.border,
            valueColor: AlwaysStoppedAnimation<Color>(C.accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
            pct < 60
                ? 'Uploading file...'
                : pct < 85
                ? 'Saving metadata...'
                : 'Anchoring on blockchain...',
            style: TextStyle(color: C.txtMuted, fontSize: 11)),
      ],
    );
  }

  // ── Error banner ─────────────────────────────────────────────
  Widget _errorBanner(_C C) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFFECACA))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFEF4444), size: 16),
        const SizedBox(width: 10),
        Expanded(
            child: Text(_uploadError!,
                style: const TextStyle(
                    color: Color(0xFFDC2626), fontSize: 13))),
        GestureDetector(
            onTap: () => setState(() => _uploadError = null),
            child: const Icon(Icons.close_rounded,
                color: Color(0xFFEF4444), size: 15)),
      ]),
    );
  }

  // ── Upload button ────────────────────────────────────────────
  Widget _uploadBtn(_C C) {
    final canUpload = _pickedFile != null
        && _selectedCaseId != null
        && !_isUploading;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: canUpload ? _upload : null,
        icon: _isUploading
            ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.cloud_upload_outlined,
            color: Colors.white, size: 18),
        label: Text(
            _isUploading
                ? 'Uploading...'
                : _pickedFile == null
                ? 'Select a file first'
                : 'Upload Evidence',
            style: const TextStyle(
                color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          disabledBackgroundColor:
          const Color(0xFF7C3AED).withOpacity(0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // SUCCESS BODY
  // ════════════════════════════════════════════════════════════
  Widget _successBody(_C C) {
    final res = _uploadResult ?? {};
    final f   = _pickedFile;

    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border),
          boxShadow: [BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              blurRadius: 40, offset: const Offset(0, 12))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 42, color: Color(0xFF059669)),
          ),

          const SizedBox(height: 20),

          Text('Evidence Uploaded!',
              style: TextStyle(
                  color: C.txtPrimary, fontSize: 22,
                  fontWeight: FontWeight.w800, letterSpacing: -0.3)),

          const SizedBox(height: 10),

          Text(
              'Your file has been uploaded to Firebase Storage\n'
                  'and is being anchored on the Polygon blockchain.',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.txtSecond,
                  fontSize: 13, height: 1.6)),

          const SizedBox(height: 20),

          // Result details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: C.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border)),
            child: Column(children: [
              _resultRow(C, 'File',
                  f?.name ?? '—',
                  Icons.insert_drive_file_outlined,
                  const Color(0xFF7C3AED)),
              const SizedBox(height: 10),
              _resultRow(C, 'Evidence ID',
                  res['evidenceId'] ?? '—',
                  Icons.tag_rounded,
                  C.accent),
              const SizedBox(height: 10),
              _resultRow(C, 'SHA-256 Hash',
                  _shortHash(res['fileHash'] ?? ''),
                  Icons.fingerprint_rounded,
                  const Color(0xFF059669)),
              const SizedBox(height: 10),
              _resultRow(C, 'Blockchain',
                  'Pending — anchoring in progress',
                  Icons.link_rounded,
                  const Color(0xFFD97706)),
            ]),
          ),

          const SizedBox(height: 28),

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _uploaded     = false;
                    _uploadResult = null;
                    _pickedFile   = null;
                    _descCtrl.clear();
                    _uploadProgress = 0;
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Upload Another'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(
                      color: Color(0xFF7C3AED), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.dashboard_outlined,
                    color: Colors.white, size: 16),
                label: const Text('Dashboard',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.accent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _resultRow(_C C, String label, String value,
      IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 10),
      Text('$label: ',
          style: TextStyle(color: C.txtSecond,
              fontSize: 12, fontWeight: FontWeight.w500)),
      Expanded(
        child: SelectableText(value,
          style: TextStyle(
              color: C.txtPrimary, fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: value.length > 20 ? 'monospace' : null),
        ),
      ),
    ]);
  }

  // ════════════════════════════════════════════════════════════
  // RIGHT PANEL
  // ════════════════════════════════════════════════════════════

  Widget _selectedFileCard(_C C) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 15, color: C.accent),
            const SizedBox(width: 7),
            Text('Selected File',
                style: TextStyle(color: C.txtPrimary,
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),

          if (_pickedFile == null)
            Column(children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 32, color: C.txtMuted),
              const SizedBox(height: 8),
              Text('No file selected',
                  style: TextStyle(
                      color: C.txtMuted, fontSize: 12)),
            ])
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File icon + name
                Row(children: [
                  Icon(
                      _typeIcon(_evidenceType ?? 'document'),
                      size: 28,
                      color: _typeColor(_evidenceType ?? 'document')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_pickedFile!.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: C.txtPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 12),
                _fileDetail(C, 'Size',
                    _formatSize(_pickedFile!.size)),
                _fileDetail(C, 'Type',
                    (_pickedFile!.extension ?? '—').toUpperCase()),
                _fileDetail(C, 'Evidence',
                    (_evidenceType ?? '—').toUpperCase()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _fileDetail(_C C, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(
              color: C.txtMuted, fontSize: 11)),
          Text(v, style: TextStyle(
              color: C.txtPrimary, fontSize: 11,
              fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _storageInfoCard(_C C) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.cloud_outlined,
                size: 15, color: Color(0xFF7C3AED)),
            const SizedBox(width: 7),
            Text('Storage Path',
                style: TextStyle(color: C.txtPrimary,
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: C.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: C.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pathRow(C, 'evidence/'),
                _pathRow(C, '  {caseId}/'),
                _pathRow(C, '    {timestamp}_{uuid}.ext'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Files are organized by case ID in Firebase Storage.',
              style: TextStyle(color: C.txtMuted,
                  fontSize: 11, height: 1.5)),
        ],
      ),
    );
  }

  Widget _pathRow(_C C, String text) {
    return Text(text,
        style: TextStyle(
            color: const Color(0xFF7C3AED),
            fontSize: 11,
            fontFamily: 'monospace'));
  }

  Widget _blockchainInfoCard(_C C) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: C.accent.withOpacity(C.isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: C.accent.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.link_rounded, size: 15, color: C.accent),
            const SizedBox(width: 7),
            Text('Blockchain Process',
                style: TextStyle(color: C.accent,
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          _blockchainStep(C, '1',
              'SHA-256 hash generated from file bytes'),
          _blockchainStep(C, '2',
              'File uploaded to Firebase Storage'),
          _blockchainStep(C, '3',
              'Metadata saved to MongoDB'),
          _blockchainStep(C, '4',
              'Hash anchored on Polygon Amoy'),
        ],
      ),
    );
  }

  Widget _blockchainStep(_C C, String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
                color: C.accent.withOpacity(0.15),
                shape: BoxShape.circle),
            child: Center(
              child: Text(n,
                  style: TextStyle(color: C.accent,
                      fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: C.txtSecond, fontSize: 11,
                      height: 1.4))),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────

  String _formatSize(int bytes) {
    if (bytes < 1024)       return '$bytes B';
    if (bytes < 1048576)    return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  String _shortHash(String hash) {
    if (hash.length < 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  Color _typeColor(String type) => switch (type) {
    'image'    => const Color(0xFF2563EB),
    'video'    => const Color(0xFF7C3AED),
    'audio'    => const Color(0xFF059669),
    'document' => const Color(0xFFD97706),
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

// ── Color palette ─────────────────────────────────────────────
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