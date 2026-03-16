import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key});
  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen>
    with SingleTickerProviderStateMixin {

  // ── Form ────────────────────────────────────────────────────
  final _formKey       = GlobalKey<FormState>();
  final _titleCtrl     = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _locationCtrl  = TextEditingController();
  final _caseRefCtrl   = TextEditingController();

  final _api = ApiService();

  String   _priority   = 'medium';
  String   _caseType   = 'criminal';
  DateTime _incidentDate = DateTime.now();
  bool     _isLoading  = false;
  bool     _submitted  = false;
  String?  _createdCaseId;
  String?  _error;

  // Focus nodes for keyboard tab navigation
  final _titleFocus    = FocusNode();
  final _descFocus     = FocusNode();
  final _locationFocus = FocusNode();
  final _refFocus      = FocusNode();

  // ── Animation ───────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double>   _entryOpacity;
  late Animation<Offset>   _entrySlide;

  final _priorities = const [
    {'value': 'low',      'label': 'Low',      'color': 0xFF059669},
    {'value': 'medium',   'label': 'Medium',   'color': 0xFFD97706},
    {'value': 'high',     'label': 'High',     'color': 0xFFDC2626},
    {'value': 'critical', 'label': 'Critical', 'color': 0xFF7C3AED},
  ];

  final _caseTypes = const [
    {'value': 'criminal',  'label': 'Criminal',  'icon': 0xe7c8},
    {'value': 'civil',     'label': 'Civil',     'icon': 0xe80f},
    {'value': 'cyber',     'label': 'Cyber',     'icon': 0xe3e8},
    {'value': 'fraud',     'label': 'Fraud',     'icon': 0xe002},
    {'value': 'narcotics', 'label': 'Narcotics', 'icon': 0xe523},
    {'value': 'other',     'label': 'Other',     'icon': 0xe88e},
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entryOpacity = _entryCtrl.drive(Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: const Interval(0, 0.65))));
    _entrySlide = _entryCtrl.drive(
        Tween(begin: const Offset(0, 0.03), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)));
    _entryCtrl.forward();

    // Auto-generate case reference number
    final now = DateTime.now();
    _caseRefCtrl.text =
    'CASE-${now.year}-${now.month.toString().padLeft(2,'0')}'
        '-${now.millisecond.toString().padLeft(4,'0')}';
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _caseRefCtrl.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _locationFocus.dispose();
    _refFocus.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await _api.createCase(
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
        priority:     _priority,
        caseType:     _caseType,
        location:     _locationCtrl.text.trim(),
        caseRef:      _caseRefCtrl.text.trim(),
        incidentDate: _incidentDate.toIso8601String(),
      );

      if (mounted) {
        setState(() {
          _submitted     = true;
          _createdCaseId = result['case']?['_id'] ?? result['_id'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to create case. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Date picker ──────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        final isDark =
            context.read<ThemeProvider>().isDark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF2563EB),
                onPrimary: Colors.white,
                surface: Color(0xFF111827),
              ))
              : ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB),
                onPrimary: Colors.white,
              )),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme  = context.watch<ThemeProvider>();
    final isDark = theme.isDark;
    final C      = _C(isDark);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: _appBar(C, isDark),
      body: FadeTransition(
        opacity: _entryOpacity,
        child: SlideTransition(
          position: _entrySlide,
          child: _submitted
              ? _successBody(C)
              : _formBody(C),
        ),
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────
  PreferredSizeWidget _appBar(_C C, bool isDark) {
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
            color: C.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.create_new_folder_outlined,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text('Create New Case',
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

        // ── Left: form fields ──────────────────────────────
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Section: Basic Info ──────────────────
                  _sectionHeader(C, 'Basic Information',
                      Icons.info_outline_rounded),
                  const SizedBox(height: 16),

                  // Case Reference (auto-generated, editable)
                  _label(C, 'Case Reference Number'),
                  const SizedBox(height: 6),
                  _field(
                    C,
                    ctrl:      _caseRefCtrl,
                    focus:     _refFocus,
                    hint:      'CASE-2024-0001',
                    icon:      Icons.tag_rounded,
                    readOnly:  false,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Reference number required' : null,
                  ),

                  const SizedBox(height: 16),

                  // Case Title
                  _label(C, 'Case Title *'),
                  const SizedBox(height: 6),
                  _field(
                    C,
                    ctrl:      _titleCtrl,
                    focus:     _titleFocus,
                    hint:      'e.g. Robbery at Central Bank',
                    icon:      Icons.title_rounded,
                    nextFocus: _descFocus,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Case title is required';
                      }
                      if (v.trim().length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description
                  _label(C, 'Description *'),
                  const SizedBox(height: 6),
                  _textArea(
                    C,
                    ctrl:      _descCtrl,
                    focus:     _descFocus,
                    hint:      'Provide a detailed description of the case...',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Description is required';
                      }
                      if (v.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Section: Classification ──────────────
                  _sectionHeader(C, 'Classification',
                      Icons.category_outlined),
                  const SizedBox(height: 16),

                  // Case Type
                  _label(C, 'Case Type *'),
                  const SizedBox(height: 10),
                  _caseTypeGrid(C),

                  const SizedBox(height: 20),

                  // Priority
                  _label(C, 'Priority Level *'),
                  const SizedBox(height: 10),
                  _priorityRow(C),

                  const SizedBox(height: 24),

                  // ── Section: Incident Details ────────────
                  _sectionHeader(C, 'Incident Details',
                      Icons.location_on_outlined),
                  const SizedBox(height: 16),

                  // Location
                  _label(C, 'Incident Location'),
                  const SizedBox(height: 6),
                  _field(
                    C,
                    ctrl:      _locationCtrl,
                    focus:     _locationFocus,
                    hint:      'e.g. 42 Main Street, Chennai',
                    icon:      Icons.location_on_outlined,
                    validator: null,
                  ),

                  const SizedBox(height: 16),

                  // Incident Date
                  _label(C, 'Incident Date *'),
                  const SizedBox(height: 6),
                  _datePicker(C),

                  const SizedBox(height: 28),

                  // Error
                  if (_error != null) ...[
                    _errorBanner(C),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  _submitBtn(C),

                  const SizedBox(height: 12),

                  // Cancel
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: C.txtSecond, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Right: info panel ──────────────────────────────
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 28, 28, 28),
            child: Column(children: [
              _infoCard(C),
              const SizedBox(height: 16),
              _previewCard(C),
              const SizedBox(height: 16),
              _tipsCard(C),
            ]),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // SUCCESS BODY
  // ════════════════════════════════════════════════════════════
  Widget _successBody(_C C) {
    return Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.1),
                blurRadius: 40, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Success icon
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 42, color: Color(0xFF059669)),
          ),

          const SizedBox(height: 20),

          Text('Case Created Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: C.txtPrimary, fontSize: 22,
                  fontWeight: FontWeight.w800, letterSpacing: -0.3)),

          const SizedBox(height: 10),

          Text(
              'Case "${_titleCtrl.text.trim()}" has been created '
                  'and registered in the system.',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.txtSecond, fontSize: 13,
                  height: 1.6)),

          const SizedBox(height: 20),

          // Case ID chip
          if (_createdCaseId != null && _createdCaseId!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: C.inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.border)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tag_rounded,
                      size: 14, color: C.accent),
                  const SizedBox(width: 6),
                  SelectableText(
                      _createdCaseId!,
                      style: TextStyle(
                          color: C.accent, fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace')),
                ],
              ),
            ),

          const SizedBox(height: 28),

          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Reset form for another case
                  setState(() {
                    _submitted = false;
                    _createdCaseId = null;
                    _titleCtrl.clear();
                    _descCtrl.clear();
                    _locationCtrl.clear();
                    _priority = 'medium';
                    _caseType = 'criminal';
                    _incidentDate = DateTime.now();
                    final now = DateTime.now();
                    _caseRefCtrl.text =
                    'CASE-${now.year}-${now.month.toString().padLeft(2,'0')}'
                        '-${now.millisecond.toString().padLeft(4,'0')}';
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Case'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.accent,
                  side: BorderSide(color: C.accent.withOpacity(0.4)),
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
                    size: 16, color: Colors.white),
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

  // ════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ════════════════════════════════════════════════════════════

  Widget _sectionHeader(_C C, String title, IconData icon) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
            color: C.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 14, color: C.accent),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
              color: C.txtPrimary, fontSize: 14,
              fontWeight: FontWeight.w700)),
      const SizedBox(width: 12),
      Expanded(child: Divider(color: C.border)),
    ]);
  }

  Widget _label(_C C, String text) {
    return Text(text,
        style: TextStyle(
            color: C.txtSecond, fontSize: 12,
            fontWeight: FontWeight.w500));
  }

  Widget _field(_C C, {
    required TextEditingController ctrl,
    required FocusNode focus,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: focus,
      readOnly: readOnly,
      validator: validator,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      style: TextStyle(
          color: C.txtPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: C.txtMuted, fontSize: 14),
        prefixIcon: Icon(icon, size: 17, color: C.txtMuted),
        filled: true,
        fillColor: readOnly ? C.inputBg.withOpacity(0.5) : C.inputBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 13, horizontal: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
                color: Color(0xFFEF4444), width: 1.5)),
        errorStyle: const TextStyle(
            color: Color(0xFFEF4444), fontSize: 11),
      ),
    );
  }

  Widget _textArea(_C C, {
    required TextEditingController ctrl,
    required FocusNode focus,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: focus,
      validator: validator,
      maxLines: 5,
      style: TextStyle(color: C.txtPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: C.txtMuted, fontSize: 14),
        filled: true,
        fillColor: C.inputBg,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
                color: Color(0xFFEF4444), width: 1.5)),
        errorStyle: const TextStyle(
            color: Color(0xFFEF4444), fontSize: 11),
      ),
    );
  }

  Widget _caseTypeGrid(_C C) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: _caseTypes.map((t) {
        final active = _caseType == t['value'];
        final icons  = {
          'criminal': Icons.local_police_outlined,
          'civil':    Icons.balance_outlined,
          'cyber':    Icons.computer_outlined,
          'fraud':    Icons.money_off_outlined,
          'narcotics':Icons.science_outlined,
          'other':    Icons.more_horiz_rounded,
        };
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _caseType = t['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? C.accent
                    : C.inputBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active
                      ? C.accent
                      : C.border,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      icons[t['value']] ?? Icons.folder_outlined,
                      size: 15,
                      color: active ? Colors.white : C.txtSecond),
                  const SizedBox(width: 7),
                  Text(t['label'] as String,
                      style: TextStyle(
                          color: active ? Colors.white : C.txtSecond,
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

  Widget _priorityRow(_C C) {
    return Row(
      children: _priorities.map((p) {
        final active = _priority == p['value'];
        final color  = Color(p['color'] as int);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: p['value'] != 'critical' ? 10 : 0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () =>
                    setState(() => _priority = p['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 11),
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
                  child: Column(children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(p['label'] as String,
                        style: TextStyle(
                            color: active ? color : C.txtSecond,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  ]),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _datePicker(_C C) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
              color: C.inputBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: C.border)),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 17, color: C.txtMuted),
            const SizedBox(width: 10),
            Text(
                '${_incidentDate.day.toString().padLeft(2,'0')} / '
                    '${_incidentDate.month.toString().padLeft(2,'0')} / '
                    '${_incidentDate.year}',
                style: TextStyle(
                    color: C.txtPrimary, fontSize: 14)),
            const Spacer(),
            Icon(Icons.edit_calendar_outlined,
                size: 15, color: C.txtMuted),
          ]),
        ),
      ),
    );
  }

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
            child: Text(_error!,
                style: const TextStyle(
                    color: Color(0xFFDC2626), fontSize: 13))),
        GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close_rounded,
                color: Color(0xFFEF4444), size: 15)),
      ]),
    );
  }

  Widget _submitBtn(_C C) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submit,
        icon: _isLoading
            ? const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.create_new_folder_outlined,
            color: Colors.white, size: 18),
        label: Text(
            _isLoading ? 'Creating Case...' : 'Create Case',
            style: const TextStyle(
                color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: C.accent,
          disabledBackgroundColor: C.accent.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // RIGHT PANEL CARDS
  // ════════════════════════════════════════════════════════════

  Widget _infoCard(_C C) {
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
            Icon(Icons.info_outline_rounded,
                size: 15, color: C.accent),
            const SizedBox(width: 7),
            Text('Case Creation Info',
                style: TextStyle(
                    color: C.txtPrimary, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          _infoRow(C, Icons.fiber_manual_record_rounded,
              'Case ID generated automatically'),
          _infoRow(C, Icons.fiber_manual_record_rounded,
              'Evidence can be added after creation'),
          _infoRow(C, Icons.fiber_manual_record_rounded,
              'All fields marked * are required'),
          _infoRow(C, Icons.fiber_manual_record_rounded,
              'Case is saved to MongoDB instantly'),
          _infoRow(C, Icons.fiber_manual_record_rounded,
              'Priority can be updated later'),
        ],
      ),
    );
  }

  Widget _infoRow(_C C, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Icon(icon, size: 6, color: C.accent)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: C.txtSecond, fontSize: 12,
                      height: 1.4))),
        ],
      ),
    );
  }

  Widget _previewCard(_C C) {
    final priorityColor = {
      'low': const Color(0xFF059669),
      'medium': const Color(0xFFD97706),
      'high': const Color(0xFFDC2626),
      'critical': const Color(0xFF7C3AED),
    };
    final color = priorityColor[_priority] ?? C.accent;

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
            Icon(Icons.preview_outlined,
                size: 15, color: C.accent),
            const SizedBox(width: 7),
            Text('Live Preview',
                style: TextStyle(
                    color: C.txtPrimary, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          // Mini case card preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: C.inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: C.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_caseRefCtrl.text.isNotEmpty
                        ? _caseRefCtrl.text : 'CASE-XXXX',
                        style: TextStyle(
                            color: C.accent, fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace')),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(_priority.toUpperCase(),
                          style: TextStyle(
                              color: color, fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _titleCtrl.text.isNotEmpty
                      ? _titleCtrl.text
                      : 'Case title will appear here',
                  style: TextStyle(
                      color: _titleCtrl.text.isNotEmpty
                          ? C.txtPrimary : C.txtMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _caseType.toUpperCase(),
                  style: TextStyle(
                      color: C.accent, fontSize: 10,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                    '${_incidentDate.day.toString().padLeft(2,'0')}/'
                        '${_incidentDate.month.toString().padLeft(2,'0')}/'
                        '${_incidentDate.year}',
                    style: TextStyle(
                        color: C.txtMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard(_C C) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: C.accent.withOpacity(C.isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: C.accent.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_outline_rounded,
                size: 15, color: C.accent),
            const SizedBox(width: 7),
            Text('Tips',
                style: TextStyle(
                    color: C.accent, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          Text(
              '• Use a clear, descriptive case title\n'
                  '• Set correct priority to manage workload\n'
                  '• Add exact location for field evidence\n'
                  '• Upload evidence immediately after case creation',
              style: TextStyle(
                  color: C.txtSecond, fontSize: 12,
                  height: 1.7)),
        ],
      ),
    );
  }
}

// ── Color palette ─────────────────────────────────────────────
class _C {
  final bool isDark;
  _C(this.isDark);
  Color get bg       => isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF0F4FF);
  Color get card     => isDark ? const Color(0xFF111827) : Colors.white;
  Color get inputBg  => isDark ? const Color(0xFF1A2540) : const Color(0xFFF8FAFF);
  Color get border   => isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0);
  Color get txtPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get txtSecond  => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get txtMuted   => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
  Color get accent     => const Color(0xFF2563EB);
}