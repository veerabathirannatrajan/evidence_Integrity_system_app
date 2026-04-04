// create_case_screen.dart
// Premium Glassmorphism UI — fully responsive (mobile + tablet + desktop)
// Fixed: all fields have visible light-grey outline when unselected
// All original logic 100% preserved.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

const double _kMobile = 600;
const double _kTablet = 1024;

// ── Field border colours ─────────────────────────────────────
const Color _kBorderIdle    = Color(0xFFD1D5DB); // visible light grey
const Color _kBorderFocus   = Color(0xFF4F46E5); // indigo when focused
const Color _kBorderError   = Color(0xFFEF4444);
const Color _kFillIdle      = Color(0xFFFAFBFF);
const Color _kFillFocus     = Color(0xFFF5F3FF);
const Color _kAccent        = Color(0xFF4F46E5);

class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key});
  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen>
    with TickerProviderStateMixin {

  // ── Form ─────────────────────────────────────────────────────
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _caseRefCtrl  = TextEditingController();
  final _api          = ApiService();

  String   _priority     = 'medium';
  String   _caseType     = 'criminal';
  DateTime _incidentDate = DateTime.now();
  bool     _isLoading    = false;
  bool     _submitted    = false;
  String?  _createdCaseId;
  String?  _error;

  final _titleFocus    = FocusNode();
  final _descFocus     = FocusNode();
  final _locationFocus = FocusNode();
  final _refFocus      = FocusNode();

  // ── Animations ───────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double>   _entryOpacity;
  late Animation<Offset>   _entrySlide;
  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;

  static const _priorities = [
    {'value': 'low',      'label': 'Low',      'color': 0xFF059669},
    {'value': 'medium',   'label': 'Medium',   'color': 0xFFD97706},
    {'value': 'high',     'label': 'High',     'color': 0xFFDC2626},
    {'value': 'critical', 'label': 'Critical', 'color': 0xFF7C3AED},
  ];

  static const _caseTypes = [
    {'value': 'criminal',  'label': 'Criminal'},
    {'value': 'civil',     'label': 'Civil'},
    {'value': 'cyber',     'label': 'Cyber'},
    {'value': 'fraud',     'label': 'Fraud'},
    {'value': 'narcotics', 'label': 'Narcotics'},
    {'value': 'other',     'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _entryOpacity = _entryCtrl.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: const Interval(0, 0.7))));
    _entrySlide   = _entryCtrl.drive(Tween(begin: const Offset(0, 0.04), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)));
    _entryCtrl.forward();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    final now = DateTime.now();
    _caseRefCtrl.text = 'CASE-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.millisecond.toString().padLeft(4, '0')}';

    _titleCtrl.addListener(() => setState(() {}));
    _caseRefCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _bgCtrl.dispose();
    _titleCtrl.dispose(); _descCtrl.dispose();
    _locationCtrl.dispose(); _caseRefCtrl.dispose();
    _titleFocus.dispose(); _descFocus.dispose();
    _locationFocus.dispose(); _refFocus.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _api.createCase(
        _titleCtrl.text.trim(), _descCtrl.text.trim(),
        priority: _priority, caseType: _caseType,
        location: _locationCtrl.text.trim(),
        caseRef: _caseRefCtrl.text.trim(),
        incidentDate: _incidentDate.toIso8601String(),
      );
      if (mounted) setState(() {
        _submitted = true;
        _createdCaseId = result['case']?['_id'] ?? result['_id'] ?? '';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to create case. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Date picker ───────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _incidentDate,
      firstDate: DateTime(2000), lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: _kAccent, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: Stack(children: [
        Positioned.fill(child: _AnimatedBg(anim: _bgAnim)),
        SafeArea(child: FadeTransition(opacity: _entryOpacity,
            child: SlideTransition(position: _entrySlide,
                child: Column(children: [
                  _buildAppBar(),
                  Expanded(child: _submitted ? _successBody() : _mainBody()),
                ])))),
      ]),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.70),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
        child: Row(children: [
          _AppBarBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 6),
          Container(width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [_kAccent, Color(0xFF6D28D9)])),
              child: const Icon(Icons.create_new_folder_outlined, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Text('Create New Case',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        ]),
      ),
    ));
  }

  // ── Responsive body ───────────────────────────────────────────
  Widget _mainBody() {
    return LayoutBuilder(builder: (_, constraints) {
      final w        = constraints.maxWidth;
      final isMobile = w < _kMobile;
      final isTablet = w >= _kMobile && w < _kTablet;

      if (isMobile) {
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
            child: Column(children: [
              _formCard(),
              const SizedBox(height: 14),
              _previewCard(),
              const SizedBox(height: 14),
              _tipsCard(),
            ]));
      }
      if (isTablet) {
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _formCard()),
              const SizedBox(width: 16),
              SizedBox(width: 240, child: Column(children: [
                _previewCard(), const SizedBox(height: 14), _tipsCard(),
              ])),
            ]));
      }
      // Desktop
      return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _formCard()),
            const SizedBox(width: 20),
            SizedBox(width: 300, child: Column(children: [
              _infoCard(), const SizedBox(height: 16),
              _previewCard(), const SizedBox(height: 16),
              _tipsCard(),
            ])),
          ]));
    });
  }

  // ── Form Card ─────────────────────────────────────────────────
  Widget _formCard() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(22),
      child: Form(key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ─ Basic Info ─────────────────────────────────────
          _SectionHeader(label: 'Basic Information', icon: Icons.info_outline_rounded),
          const SizedBox(height: 14),

          _FieldLabel(label: 'Case Reference Number'),
          const SizedBox(height: 6),
          _Field(ctrl: _caseRefCtrl, focus: _refFocus,
              hint: 'CASE-2024-0001', icon: Icons.tag_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Reference number required' : null),
          const SizedBox(height: 14),

          _FieldLabel(label: 'Case Title *'),
          const SizedBox(height: 6),
          _Field(ctrl: _titleCtrl, focus: _titleFocus, nextFocus: _descFocus,
              hint: 'e.g. Robbery at Central Bank', icon: Icons.title_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Case title is required';
                if (v.trim().length < 5) return 'Title must be at least 5 characters';
                return null;
              }),
          const SizedBox(height: 14),

          _FieldLabel(label: 'Description *'),
          const SizedBox(height: 6),
          _TextArea(ctrl: _descCtrl, focus: _descFocus,
              hint: 'Provide a detailed description of the case...',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Description is required';
                if (v.trim().length < 10) return 'Description must be at least 10 characters';
                return null;
              }),

          const SizedBox(height: 22),
          // ─ Classification ─────────────────────────────────
          _SectionHeader(label: 'Classification', icon: Icons.category_outlined),
          const SizedBox(height: 14),

          _FieldLabel(label: 'Case Type *'),
          const SizedBox(height: 10),
          _caseTypeGrid(),
          const SizedBox(height: 18),

          _FieldLabel(label: 'Priority Level *'),
          const SizedBox(height: 10),
          _priorityRow(),

          const SizedBox(height: 22),
          // ─ Incident Details ────────────────────────────────
          _SectionHeader(label: 'Incident Details', icon: Icons.location_on_outlined),
          const SizedBox(height: 14),

          _FieldLabel(label: 'Incident Location'),
          const SizedBox(height: 6),
          _Field(ctrl: _locationCtrl, focus: _locationFocus,
              hint: 'e.g. 42 Main Street, Chennai', icon: Icons.location_on_outlined,
              validator: null),
          const SizedBox(height: 14),

          _FieldLabel(label: 'Incident Date *'),
          const SizedBox(height: 6),
          _datePicker(),

          const SizedBox(height: 22),
          if (_error != null) ...[_errorBanner(), const SizedBox(height: 14)],
          _submitBtn(),
          const SizedBox(height: 10),
          Center(child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          )),
        ]),
      ),
    ));
  }

  // ── Case Type Grid ────────────────────────────────────────────
  Widget _caseTypeGrid() {
    final icons = {
      'criminal': Icons.local_police_outlined, 'civil': Icons.balance_outlined,
      'cyber': Icons.computer_outlined, 'fraud': Icons.money_off_outlined,
      'narcotics': Icons.science_outlined, 'other': Icons.more_horiz_rounded,
    };
    return Wrap(spacing: 8, runSpacing: 8,
      children: _caseTypes.map((t) {
        final active = _caseType == t['value'];
        return MouseRegion(cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _caseType = t['value'] as String),
            child: AnimatedContainer(duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [_kAccent, Color(0xFF6D28D9)]) : null,
                color: active ? null : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: active ? _kAccent : _kBorderIdle,
                    width: active ? 1.5 : 1.2),
                boxShadow: active ? [BoxShadow(color: _kAccent.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 3))] : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icons[t['value']] ?? Icons.folder_outlined, size: 15,
                    color: active ? Colors.white : const Color(0xFF64748B)),
                const SizedBox(width: 7),
                Text(t['label'] as String, style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF475569),
                    fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Priority Row ──────────────────────────────────────────────
  Widget _priorityRow() {
    return Row(
      children: List.generate(_priorities.length, (i) {
        final p      = _priorities[i];
        final active = _priority == p['value'];
        final color  = Color(p['color'] as int);
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: i < _priorities.length - 1 ? 8 : 0),
          child: MouseRegion(cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _priority = p['value'] as String),
              child: AnimatedContainer(duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active ? color : _kBorderIdle,
                      width: active ? 1.8 : 1.2),
                  boxShadow: active ? [BoxShadow(color: color.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
                child: Column(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)] : [])),
                  const SizedBox(height: 5),
                  Text(p['label'] as String, style: TextStyle(
                      color: active ? color : const Color(0xFF64748B),
                      fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                ]),
              ),
            ),
          ),
        ));
      }),
    );
  }

  // ── Date Picker ───────────────────────────────────────────────
  Widget _datePicker() {
    return MouseRegion(cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _kFillIdle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorderIdle, width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(width: 32, height: 32,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                    color: _kAccent.withOpacity(0.08)),
                child: const Icon(Icons.calendar_today_outlined, size: 16, color: _kAccent)),
            const SizedBox(width: 12),
            Text(
              '${_incidentDate.day.toString().padLeft(2,'0')} / ${_incidentDate.month.toString().padLeft(2,'0')} / ${_incidentDate.year}',
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _kAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: const Text('Change', style: TextStyle(color: _kAccent, fontSize: 11, fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
    );
  }

  // ── Error Banner ──────────────────────────────────────────────
  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEF4444).withOpacity(0.1)),
            child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 17)),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
        GestureDetector(onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16)),
      ]),
    );
  }

  // ── Submit Button ─────────────────────────────────────────────
  Widget _submitBtn() {
    return Container(
      width: double.infinity, height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _isLoading ? null : const LinearGradient(colors: [_kAccent, Color(0xFF6D28D9)]),
        color: _isLoading ? _kAccent.withOpacity(0.45) : null,
        boxShadow: _isLoading ? [] : [
          BoxShadow(color: _kAccent.withOpacity(0.38), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(color: Colors.transparent,
        child: InkWell(onTap: _isLoading ? null : _submit,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.15),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_isLoading)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            else
              const Icon(Icons.create_new_folder_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(_isLoading ? 'Creating Case...' : 'Create Case',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ])),
        ),
      ),
    );
  }

  // ── Info Card ─────────────────────────────────────────────────
  Widget _infoCard() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _CardHeader(icon: Icons.info_outline_rounded, label: 'Case Creation Info', color: _kAccent),
          const SizedBox(height: 14),
          ...[
            'Case ID generated automatically',
            'Evidence can be added after creation',
            'All fields marked * are required',
            'Case is saved to MongoDB instantly',
            'Priority can be updated later',
          ].map((t) => Padding(padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(t, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.5))),
              ]))),
        ])));
  }

  // ── Preview Card ──────────────────────────────────────────────
  Widget _previewCard() {
    const priorityColors = {
      'low': Color(0xFF059669), 'medium': Color(0xFFD97706),
      'high': Color(0xFFDC2626), 'critical': Color(0xFF7C3AED),
    };
    final pColor = priorityColors[_priority] ?? _kAccent;

    return _GlassCard(child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _CardHeader(icon: Icons.preview_outlined, label: 'Live Preview', color: _kAccent),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorderIdle),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(_caseRefCtrl.text.isNotEmpty ? _caseRefCtrl.text : 'CASE-XXXX',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kAccent, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: pColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(_priority.toUpperCase(), style: TextStyle(color: pColor, fontSize: 9, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 8),
              Text(_titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Case title will appear here',
                  style: TextStyle(color: _titleCtrl.text.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_caseType.toUpperCase(), style: const TextStyle(color: _kAccent, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text('${_incidentDate.day.toString().padLeft(2,'0')}/${_incidentDate.month.toString().padLeft(2,'0')}/${_incidentDate.year}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ]),
            ]),
          ),
        ])));
  }

  // ── Tips Card ─────────────────────────────────────────────────
  Widget _tipsCard() {
    return _GlassCard(tint: const Color(0xFFF0F9FF), child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _CardHeader(icon: Icons.lightbulb_outline_rounded, label: 'Tips', color: _kAccent),
          const SizedBox(height: 12),
          ...[
            'Use a clear, descriptive case title',
            'Set correct priority to manage workload',
            'Add exact location for field evidence',
            'Upload evidence immediately after creation',
          ].map((t) => Padding(padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.arrow_right_rounded, size: 16, color: _kAccent),
                const SizedBox(width: 4),
                Expanded(child: Text(t, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.5))),
              ]))),
        ])));
  }

  // ── Success Body ──────────────────────────────────────────────
  Widget _successBody() {
    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
        child: _GlassCard(child: Padding(padding: const EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(width: 88, height: 88,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF0D9488)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))]),
                  child: const Icon(Icons.check_rounded, size: 44, color: Colors.white)),
            ),
            const SizedBox(height: 24),
            const Text('Case Created Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 10),
            Text('Case "${_titleCtrl.text.trim()}" has been created and registered in the system.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.6)),
            if (_createdCaseId != null && _createdCaseId!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorderIdle),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 28, height: 28,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _kAccent.withOpacity(0.1)),
                        child: const Icon(Icons.tag_rounded, size: 14, color: _kAccent)),
                    const SizedBox(width: 10),
                    SelectableText(_createdCaseId!,
                        style: const TextStyle(color: _kAccent, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                  ])),
            ],
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: _OutlineBtn(label: 'New Case', icon: Icons.add_rounded,
                  onTap: () => setState(() {
                    _submitted = false; _createdCaseId = null;
                    _titleCtrl.clear(); _descCtrl.clear(); _locationCtrl.clear();
                    _priority = 'medium'; _caseType = 'criminal'; _incidentDate = DateTime.now();
                    final now = DateTime.now();
                    _caseRefCtrl.text = 'CASE-${now.year}-${now.month.toString().padLeft(2,'0')}-${now.millisecond.toString().padLeft(4,'0')}';
                  }))),
              const SizedBox(width: 12),
              Expanded(child: _GradBtn(label: 'Dashboard', icon: Icons.dashboard_outlined,
                  onTap: () => Navigator.pop(context))),
            ]),
          ]),
        )),
      )),
    ));
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _AnimatedBg extends StatelessWidget {
  final Animation<double> anim;
  const _AnimatedBg({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: anim, builder: (_, __) {
      final t = anim.value;
      return Container(color: const Color(0xFFEEF2FF), child: Stack(children: [
        Positioned(left: -120 + t * 70, top: -90 + t * 50,
            child: _orb(320, const Color(0xFF4F46E5), 0.12)),
        Positioned(right: -80 + t * 40, bottom: 30 + t * 80,
            child: _orb(260, const Color(0xFF7C3AED), 0.10)),
        Positioned(left: MediaQuery.of(context).size.width * 0.4,
            top: MediaQuery.of(context).size.height * 0.3 - t * 50,
            child: _orb(180, const Color(0xFF2563EB), 0.08)),
      ]));
    });
  }
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
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: _kAccent.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -2),
        BoxShadow(color: Colors.white.withOpacity(0.85), blurRadius: 1, offset: const Offset(0, -1)),
      ],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.68), width: 1.3),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [(tint ?? Colors.white).withOpacity(0.90), (tint ?? Colors.white).withOpacity(0.60)]),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 30, height: 30,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(colors: [_kAccent, Color(0xFF6D28D9)])),
        child: Icon(icon, size: 15, color: Colors.white)),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
    const SizedBox(width: 14),
    Expanded(child: Container(height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [_kAccent.withOpacity(0.3), Colors.transparent])))),
  ]);
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1));
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CardHeader({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 28, height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.1)),
        child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 9),
    Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}

/// Premium text field with VISIBLE outline when idle (light grey border),
/// indigo glow when focused.
class _Field extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String hint;
  final IconData icon;
  final bool readOnly;
  final FocusNode? nextFocus;
  final String? Function(String?)? validator;

  const _Field({required this.ctrl, required this.focus, required this.hint,
    required this.icon, this.readOnly = false, this.nextFocus, this.validator});

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focus.addListener(() { if (mounted) setState(() => _focused = widget.focus.hasFocus); });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _focused
            ? [BoxShadow(color: _kAccent.withOpacity(0.20), blurRadius: 12, offset: const Offset(0, 3), spreadRadius: -1)]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: widget.ctrl, focusNode: widget.focus,
        readOnly: widget.readOnly, validator: widget.validator,
        textInputAction: widget.nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) { if (widget.nextFocus != null) FocusScope.of(context).requestFocus(widget.nextFocus); },
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: Container(margin: const EdgeInsets.all(10), width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                  color: _focused ? _kAccent.withOpacity(0.08) : const Color(0xFFF3F4F6)),
              child: Icon(widget.icon, size: 16, color: _focused ? _kAccent : const Color(0xFF9CA3AF))),
          filled: true,
          fillColor: _focused ? _kFillFocus : (widget.readOnly ? const Color(0xFFF9FAFB) : _kFillIdle),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          // ── Visible borders at every state ──────────────
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderFocus, width: 2.0)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderError, width: 1.2)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderError, width: 2.0)),
          errorStyle: const TextStyle(color: _kBorderError, fontSize: 11),
        ),
      ),
    );
  }
}

/// Premium multi-line text area with visible outline at all states.
class _TextArea extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String hint;
  final String? Function(String?)? validator;
  const _TextArea({required this.ctrl, required this.focus, required this.hint, this.validator});

  @override
  State<_TextArea> createState() => _TextAreaState();
}

class _TextAreaState extends State<_TextArea> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focus.addListener(() { if (mounted) setState(() => _focused = widget.focus.hasFocus); });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _focused
            ? [BoxShadow(color: _kAccent.withOpacity(0.20), blurRadius: 12, offset: const Offset(0, 3), spreadRadius: -1)]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: widget.ctrl, focusNode: widget.focus,
        validator: widget.validator, maxLines: 5,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          filled: true, fillColor: _focused ? _kFillFocus : _kFillIdle,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderFocus, width: 2.0)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderError, width: 1.2)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderError, width: 2.0)),
          errorStyle: const TextStyle(color: _kBorderError, fontSize: 11),
        ),
      ),
    );
  }
}

class _AppBarBtn extends StatefulWidget {
  final IconData icon; final VoidCallback onTap;
  const _AppBarBtn({required this.icon, required this.onTap});
  @override State<_AppBarBtn> createState() => _AppBarBtnState();
}
class _AppBarBtnState extends State<_AppBarBtn> {
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

class _GradBtn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _GradBtn({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(height: 46,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [_kAccent, Color(0xFF6D28D9)]),
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