// dashboard_widgets.dart — Premium Glassmorphism Shared Widgets
// Fixed: No theme toggle, no overflow, correct Scaffold context handling

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';

// ── Breakpoints ───────────────────────────────────────────────
const double kMobile = 600;
const double kTablet = 1024;

// ── DC — colour helper (backward compat) ──────────────────────
class DC {
  final bool isDark;
  DC(this.isDark);
  Color get bg         => const Color(0xFFEEF2FF);
  Color get sidebar    => const Color(0xFFF8F9FF);
  Color get card       => Colors.white;
  Color get inputBg    => const Color(0xFFF1F5FF);
  Color get border     => const Color(0xFFE2E8F0);
  Color get txtPrimary => const Color(0xFF0F172A);
  Color get txtSecond  => const Color(0xFF475569);
  Color get txtMuted   => const Color(0xFF94A3B8);
  Color get accent     => const Color(0xFF4F46E5);
}

// ── Role helpers ──────────────────────────────────────────────
String roleLabel(String r) => switch (r) {
  'police'     => 'Police Officer',
  'forensic'   => 'Forensic Expert',
  'prosecutor' => 'Prosecutor',
  'defense'    => 'Defense Attorney',
  'court'      => 'Court Official',
  _            => 'Officer',
};

Color roleColor(String r) => switch (r) {
  'police'     => const Color(0xFF4F46E5),
  'forensic'   => const Color(0xFF7C3AED),
  'prosecutor' => const Color(0xFF059669),
  'defense'    => const Color(0xFF0284C7),
  'court'      => const Color(0xFFD97706),
  _            => const Color(0xFF4F46E5),
};

IconData roleIcon(String r) => switch (r) {
  'police'     => Icons.local_police_outlined,
  'forensic'   => Icons.biotech_outlined,
  'prosecutor' => Icons.gavel_outlined,
  'defense'    => Icons.balance_outlined,
  'court'      => Icons.account_balance_outlined,
  _            => Icons.person_outline,
};

List<Color> roleBannerColors(String r) => switch (r) {
  'police'     => [const Color(0xFF3B4EFF), const Color(0xFF2563EB), const Color(0xFF4F46E5), const Color(0xFF6D28D9)],
  'forensic'   => [const Color(0xFF5B21B6), const Color(0xFF6D28D9), const Color(0xFF7C3AED), const Color(0xFF4338CA)],
  'prosecutor' => [const Color(0xFF065F46), const Color(0xFF047857), const Color(0xFF059669), const Color(0xFF0D9488)],
  'defense'    => [const Color(0xFF075985), const Color(0xFF0369A1), const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
  'court'      => [const Color(0xFF78350F), const Color(0xFF92400E), const Color(0xFFB45309), const Color(0xFFD97706)],
  _            => [const Color(0xFF3B4EFF), const Color(0xFF2563EB), const Color(0xFF4F46E5), const Color(0xFF6D28D9)],
};

String timeAgo(String? raw) {
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

// ── GlassCard ────────────────────────────────────────────────
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool hoverable;
  final Color? tint;
  const GlassCard({super.key, required this.child, this.padding,
    this.radius = 20, this.hoverable = false, this.tint});
  @override State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  bool _hov = false;
  late AnimationController _c;
  late Animation<double> _sc, _gl;
  @override
  void initState() {
    super.initState();
    _c  = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _sc = Tween(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _gl = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { if (widget.hoverable) { setState(() => _hov = true);  _c.forward(); }},
      onExit:  (_) { if (widget.hoverable) { setState(() => _hov = false); _c.reverse(); }},
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(
          scale: _sc.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(color: (widget.tint ?? const Color(0xFF4F46E5)).withOpacity(0.07 + _gl.value * 0.06),
                    blurRadius: 20 + _gl.value * 14, offset: Offset(0, 8 + _gl.value * 3), spreadRadius: -2),
                BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 1, offset: const Offset(0, -1)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: Border.all(color: Colors.white.withOpacity(_hov ? 0.88 : 0.65), width: 1.3),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [(widget.tint ?? Colors.white).withOpacity(0.88),
                          (widget.tint ?? Colors.white).withOpacity(0.55)]),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

// ── GlassBackground ──────────────────────────────────────────
class GlassBackground extends StatefulWidget {
  final String role;
  const GlassBackground({super.key, required this.role});
  @override State<GlassBackground> createState() => _GlassBgState();
}

class _GlassBgState extends State<GlassBackground> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cols = roleBannerColors(widget.role);
    return AnimatedBuilder(animation: _a, builder: (_, __) {
      final t = _a.value;
      return Container(color: const Color(0xFFEEF2FF),
          child: Stack(children: [
            Positioned(left: -120 + t * 70, top: -90 + t * 50, child: _orb(340, cols[0], 0.12)),
            Positioned(right: -80 + t * 40, bottom: 30 + t * 90, child: _orb(280, cols[2], 0.10)),
            Positioned(left: MediaQuery.of(context).size.width * 0.38,
                top: MediaQuery.of(context).size.height * 0.28 - t * 55,
                child: _orb(200, cols[1], 0.08)),
          ]));
    });
  }
  Widget _orb(double sz, Color c, double op) => Container(width: sz, height: sz,
      decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c.withOpacity(op), c.withOpacity(0)])));
}

// ── FadeSlide ────────────────────────────────────────────────
class FadeSlide extends StatefulWidget {
  final Widget child; final int delayMs; final Offset from;
  const FadeSlide({super.key, required this.child, this.delayMs = 0, this.from = const Offset(0, 24)});
  @override State<FadeSlide> createState() => _FadeSlideState();
}
class _FadeSlideState extends State<FadeSlide> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _f; late Animation<Offset> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _f = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _s = Tween<Offset>(begin: widget.from, end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c,
      builder: (_, child) => FadeTransition(opacity: _f,
          child: Transform.translate(offset: _s.value, child: child)),
      child: widget.child);
}

// ── DashboardAppBar — NO theme toggle ────────────────────────
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DC C;
  final String title;
  final bool sidebarExpanded;
  final VoidCallback onMenuTap;
  final VoidCallback onRefresh;
  final ThemeProvider theme; // kept for API compat, not used visually
  final String role;

  const DashboardAppBar({super.key, required this.C, required this.title,
    required this.sidebarExpanded, required this.onMenuTap, required this.onRefresh,
    required this.theme, required this.role});

  @override Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.68),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
          child: Row(children: [
            _ABBtn(icon: sidebarExpanded ? Icons.menu_open_rounded : Icons.menu_rounded, onTap: onMenuTap),
            const SizedBox(width: 12),
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15,
                    fontWeight: FontWeight.w700, letterSpacing: -0.3))),
            _ABBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
            const SizedBox(width: 8),
            _RoleBadge(role: role),
          ]),
        ),
      ),
    );
  }
}

class _ABBtn extends StatefulWidget {
  final IconData icon; final VoidCallback onTap;
  const _ABBtn({required this.icon, required this.onTap});
  @override State<_ABBtn> createState() => _ABBtnState();
}
class _ABBtnState extends State<_ABBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
            width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                color: _h ? const Color(0xFF4F46E5).withOpacity(0.08) : Colors.transparent,
                border: Border.all(color: _h ? const Color(0xFF4F46E5).withOpacity(0.2) : Colors.transparent)),
            child: Icon(widget.icon, size: 18,
                color: _h ? const Color(0xFF4F46E5) : const Color(0xFF475569)))),
  );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});
  @override
  Widget build(BuildContext context) {
    final c = roleColor(role);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.22))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(roleIcon(role), size: 11, color: c),
          const SizedBox(width: 4),
          Text(roleLabel(role), style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)),
        ]));
  }
}

// ── DashboardSidebar ─────────────────────────────────────────
class DashboardSidebar extends StatefulWidget {
  final DC C; final bool expanded; final String role, email;
  final List<Map<String, dynamic>> navItems;
  final void Function(String) onNavTap;
  final VoidCallback onLogout;
  const DashboardSidebar({super.key, required this.C, required this.expanded,
    required this.role, required this.email, required this.navItems,
    required this.onNavTap, required this.onLogout});
  @override State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  int _hov = -1;
  @override
  Widget build(BuildContext context) {
    final exp    = widget.expanded;
    final rColor = roleColor(widget.role);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: exp ? 240.0 : 64.0,
      child: ClipRect(
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFF8F9FF), Color(0xFFEEF0FF)]),
                border: Border(right: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5)),
                boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.06), blurRadius: 24, offset: const Offset(4, 0))]),
            child: Column(children: [
              // Logo
              AnimatedContainer(duration: const Duration(milliseconds: 300), height: 64,
                  padding: EdgeInsets.symmetric(horizontal: exp ? 18 : 14),
                  child: Row(children: [
                    Container(width: 38, height: 38,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                colors: [rColor, rColor.withOpacity(0.7)]),
                            boxShadow: [BoxShadow(color: rColor.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
                        child: Icon(roleIcon(widget.role), color: Colors.white, size: 20)),
                    if (exp) ...[
                      const SizedBox(width: 10),
                      Flexible(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('EvidenceChain', overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Color(0xFF0F172A), fontSize: 13,
                                    fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                            Text('Blockchain System', overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: rColor, fontSize: 10, fontWeight: FontWeight.w500)),
                          ])),
                    ],
                  ])),
              Container(height: 1, color: Colors.white.withOpacity(0.6)),
              const SizedBox(height: 6),
              // User chip
              AnimatedContainer(duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: exp ? 10 : 8, vertical: 4),
                  padding: EdgeInsets.symmetric(horizontal: exp ? 10 : 8, vertical: 8),
                  decoration: BoxDecoration(color: rColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: rColor.withOpacity(0.15))),
                  child: Row(children: [
                    Container(width: 28, height: 28,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [rColor, rColor.withOpacity(0.7)]),
                            boxShadow: [BoxShadow(color: rColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]),
                        child: Center(child: Text(widget.email.isNotEmpty ? widget.email[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)))),
                    if (exp) ...[
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.email.split('@').first, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(roleLabel(widget.role), overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: rColor, fontSize: 9, fontWeight: FontWeight.w600)),
                      ])),
                    ],
                  ])),
              const SizedBox(height: 4),
              // Nav
              Expanded(child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: exp ? 10 : 8, vertical: 4),
                  itemCount: widget.navItems.length,
                  itemBuilder: (_, i) {
                    final item = widget.navItems[i];
                    if (item['section'] == true) {
                      return AnimatedOpacity(opacity: exp ? 1.0 : 0.0, duration: const Duration(milliseconds: 200),
                          child: Padding(padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                              child: Text(item['label'] as String, style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.4))));
                    }
                    final hov = _hov == i;
                    return MouseRegion(cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _hov = i),
                        onExit:  (_) => setState(() => _hov = -1),
                        child: GestureDetector(onTap: () => widget.onNavTap(item['screen'] as String),
                            child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: EdgeInsets.symmetric(horizontal: exp ? 12 : 10, vertical: 10),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                                    color: hov ? rColor.withOpacity(0.08) : Colors.transparent,
                                    border: Border.all(color: hov ? rColor.withOpacity(0.18) : Colors.transparent)),
                                child: Row(mainAxisAlignment: exp ? MainAxisAlignment.start : MainAxisAlignment.center,
                                    children: [
                                      Icon(item['icon'] as IconData, size: 18,
                                          color: hov ? rColor : const Color(0xFF64748B)),
                                      if (exp) ...[
                                        const SizedBox(width: 10),
                                        Flexible(child: Text(item['label'] as String, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: hov ? rColor : const Color(0xFF475569),
                                                fontSize: 13, fontWeight: hov ? FontWeight.w600 : FontWeight.w500))),
                                      ],
                                    ]))));
                  })),
              Container(height: 1, color: Colors.white.withOpacity(0.6)),
              // User + logout
              AnimatedContainer(duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(horizontal: exp ? 14 : 10, vertical: 12),
                  child: Row(children: [
                    Container(width: 34, height: 34,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [rColor, rColor.withOpacity(0.7)]),
                            boxShadow: [BoxShadow(color: rColor.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Center(child: Text(widget.email.isNotEmpty ? widget.email[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)))),
                    if (exp) ...[
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.email.split('@').first, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(roleLabel(widget.role), overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: rColor, fontSize: 10)),
                      ])),
                      SizedBox(width: 32, height: 32,
                          child: IconButton(icon: const Icon(Icons.logout_rounded, size: 15, color: Color(0xFFEF4444)),
                              onPressed: widget.onLogout, tooltip: 'Logout', padding: EdgeInsets.zero)),
                    ],
                  ])),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── StatCard ─────────────────────────────────────────────────
class StatCard extends StatefulWidget {
  final DC C; final String label, value, sub; final IconData icon;
  final Color color; final bool loading; final VoidCallback onTap;
  const StatCard({super.key, required this.C, required this.label, required this.value,
    required this.sub, required this.icon, required this.color,
    required this.loading, required this.onTap});
  @override State<StatCard> createState() => _StatCardState();
}
class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  bool _hov = false;
  late AnimationController _c; late Animation<double> _sc, _gl;
  @override
  void initState() {
    super.initState();
    _c  = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _sc = Tween(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _gl = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) { setState(() => _hov = true);  _c.forward(); },
      onExit:  (_) { setState(() => _hov = false); _c.reverse(); },
      child: GestureDetector(onTap: widget.onTap,
          child: AnimatedBuilder(animation: _c,
              builder: (_, __) => Transform.scale(scale: _sc.value,
                  child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: widget.color.withOpacity(0.12 + _gl.value * 0.12),
                                blurRadius: 24 + _gl.value * 12, offset: Offset(0, 8 + _gl.value * 3), spreadRadius: -2),
                            BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 2, offset: const Offset(0, -1)),
                          ]),
                      child: ClipRRect(borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(_hov ? 0.9 : 0.65), width: 1.5),
                                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                          colors: [Colors.white.withOpacity(0.88), Colors.white.withOpacity(0.55)])),
                                  child: widget.loading ? _shimmer() : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                          Container(width: 40, height: 40,
                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                                                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                                      colors: [widget.color, widget.color.withOpacity(0.7)]),
                                                  boxShadow: [BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
                                              child: Icon(widget.icon, color: Colors.white, size: 18)),
                                          AnimatedBuilder(animation: _gl,
                                              builder: (_, __) => Container(width: 7, height: 7,
                                                  decoration: BoxDecoration(shape: BoxShape.circle,
                                                      color: widget.color.withOpacity(0.4 + _gl.value * 0.6),
                                                      boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 5, spreadRadius: 1)]))),
                                        ]),
                                        const SizedBox(height: 12),
                                        Text(widget.value, style: TextStyle(color: const Color(0xFF0F172A),
                                            fontSize: widget.value.length > 6 ? 18 : 24,
                                            fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1)),
                                        const SizedBox(height: 3),
                                        Text(widget.label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(widget.sub, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                        const SizedBox(height: 10),
                                        LinearProgressIndicator(value: null,
                                            backgroundColor: widget.color.withOpacity(0.08),
                                            valueColor: AlwaysStoppedAnimation(widget.color.withOpacity(0.3)),
                                            borderRadius: BorderRadius.circular(4), minHeight: 3),
                                      ])))))))));
  Widget _shimmer() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sr(40, 40, r: 12), const SizedBox(height: 12),
    _sr(50, 24), const SizedBox(height: 5), _sr(80, 11), const SizedBox(height: 4), _sr(60, 10)]);
  Widget _sr(double w, double h, {double r = 8}) => Container(width: w, height: h,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(r)));
}

// ── StatsGrid ────────────────────────────────────────────────
class StatsGrid extends StatelessWidget {
  final List<StatCard> cards;
  const StatsGrid({super.key, required this.cards});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    final w = c.maxWidth;
    if (w < kMobile) return GridView.count(crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.88, children: cards);
    if (w < kTablet) return GridView.count(crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35, children: cards);
    return Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(cards.length, (i) => [
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12)
        ]).expand((e) => e).toList());
  });
}

// ── ActionCard ───────────────────────────────────────────────
class ActionCard extends StatefulWidget {
  final DC C; final String label, sub; final IconData icon;
  final Color color; final VoidCallback onTap;
  const ActionCard({super.key, required this.C, required this.label, required this.sub,
    required this.icon, required this.color, required this.onTap});
  @override State<ActionCard> createState() => _ActionCardState();
}
class _ActionCardState extends State<ActionCard> with SingleTickerProviderStateMixin {
  bool _hov = false;
  late AnimationController _c; late Animation<double> _is, _li;
  @override
  void initState() {
    super.initState();
    _c  = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _is = Tween(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _li = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) { setState(() => _hov = true);  _c.forward(); },
      onExit:  (_) { setState(() => _hov = false); _c.reverse(); },
      child: GestureDetector(onTap: widget.onTap,
          child: AnimatedBuilder(animation: _c,
              builder: (_, __) => Transform.translate(offset: Offset(0, -_li.value * 2),
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                          color: _hov ? widget.color.withOpacity(0.06) : Colors.white.withOpacity(0.55),
                          border: Border.all(color: _hov ? widget.color.withOpacity(0.25) : Colors.white.withOpacity(0.7), width: 1.2),
                          boxShadow: [BoxShadow(color: widget.color.withOpacity(_hov ? 0.09 : 0.02),
                              blurRadius: _hov ? 12 : 3, offset: const Offset(0, 3))]),
                      child: Row(children: [
                        AnimatedBuilder(animation: _is,
                            builder: (_, __) => Transform.scale(scale: _is.value,
                                child: Container(width: 34, height: 34,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                            colors: [widget.color, widget.color.withOpacity(0.7)]),
                                        boxShadow: [BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                                    child: Icon(widget.icon, color: Colors.white, size: 16)))),
                        const SizedBox(width: 11),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(widget.sub,   style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        ])),
                        AnimatedRotation(turns: _hov ? 0.04 : 0, duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.arrow_forward_ios_rounded, size: 11,
                                color: _hov ? widget.color : const Color(0xFF94A3B8))),
                      ]))))));
      }

// ── ActivityRow ──────────────────────────────────────────────
      class ActivityRow extends StatelessWidget {
  final DC C; final Map<String, dynamic> item; final bool isLast;
  const ActivityRow({super.key, required this.C, required this.item, required this.isLast});
  @override
  Widget build(BuildContext context) {
  final type   = item['_type'] as String? ?? 'evidence';
  final isEv   = type == 'evidence';
  final status = item['blockchainStatus'] ?? 'pending';
  final tamper = item['isTampered'] == true;
  Color color; IconData icon; String title, sub;
  if (isEv) {
  if (tamper) { color = const Color(0xFFDC2626); icon = Icons.warning_amber_rounded; title = '⚠️ Tamper detected!'; sub = item['fileName'] ?? '—'; }
  else if (status == 'anchored') { color = const Color(0xFF059669); icon = Icons.verified_outlined; title = 'Evidence anchored on blockchain'; sub = item['fileName'] ?? '—'; }
  else { color = const Color(0xFF4F46E5); icon = Icons.upload_file_outlined; title = 'Evidence uploaded'; sub = item['fileName'] ?? '—'; }
  } else { color = const Color(0xFF7C3AED); icon = Icons.swap_horiz_rounded; title = 'Custody transferred'; sub = 'To: ${item['toUser'] ?? '—'}  ·  ${item['reason'] ?? ''}'; }
  final rawTime = item['createdAt'] ?? item['timestamp'];
  return Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Column(children: [
  Container(width: 32, height: 32,
  decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
  border: Border.all(color: color.withOpacity(0.15))),
  child: Icon(icon, size: 15, color: color)),
  if (!isLast) Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(vertical: 3),
  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
  colors: [color.withOpacity(0.2), Colors.transparent]))),
  ]),
  const SizedBox(width: 10),
  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  Expanded(child: Text(title, overflow: TextOverflow.ellipsis,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600))),
  Text(timeAgo(rawTime?.toString()), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
  ]),
  const SizedBox(height: 2),
  Text(sub, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
  ])),
  ]));
  }
  }

// ── WelcomeBanner ────────────────────────────────────────────
      class WelcomeBanner extends StatelessWidget {
  final String email, role, subtitle;
  final Map<String, String> stats;
  final Animation<double> pulse;
  const WelcomeBanner({super.key, required this.email, required this.role,
  required this.subtitle, required this.stats, required this.pulse});
  @override
  Widget build(BuildContext context) {
  final h     = DateTime.now().hour;
  final g     = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  final name  = email.split('@').first;
  final cols  = roleBannerColors(role);
  final isMob = MediaQuery.of(context).size.width < kMobile;
  return Container(
  width: double.infinity,
  padding: EdgeInsets.all(isMob ? 16 : 22),
  decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(22),
  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: cols, stops: const [0.0, 0.33, 0.66, 1.0]),
  boxShadow: [
  BoxShadow(color: cols[1].withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 10), spreadRadius: -4),
  BoxShadow(color: cols[2].withOpacity(0.18), blurRadius: 50, offset: const Offset(0, 20), spreadRadius: -8),
  ]),
  child: Stack(children: [
  Positioned(right: -40, top: -40, child: Container(width: 150, height: 150,
  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
  Positioned(right: 50, bottom: -25, child: Container(width: 90, height: 90,
  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
  Positioned(top: 0, left: 0, right: 0, child: Container(height: 1,
  decoration: BoxDecoration(gradient: LinearGradient(colors: [
  Colors.transparent, Colors.white.withOpacity(0.3), Colors.transparent])))),
  Padding(padding: const EdgeInsets.all(2),
  child: isMob
  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  _badge(), const SizedBox(height: 9),
  Text('$g, $name!', style: const TextStyle(color: Colors.white, fontSize: 20,
  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
  const SizedBox(height: 3),
  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
  const SizedBox(height: 12),
  Wrap(spacing: 8, runSpacing: 8,
  children: stats.entries.map((e) => _pill(e.key, e.value)).toList()),
  ])
      : Row(children: [
  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  _badge(), const SizedBox(height: 9),
  Text('$g, $name!', style: const TextStyle(color: Colors.white, fontSize: 23,
  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
  const SizedBox(height: 3),
  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12)),
  ])),
  const SizedBox(width: 14),
  Wrap(spacing: 8, children: stats.entries.map((e) => _pill(e.key, e.value)).toList()),
  ])),
  ]));
  }
  Widget _badge() => AnimatedBuilder(animation: pulse,
  builder: (_, __) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
  borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
  Transform.scale(scale: pulse.value, child: Container(width: 6, height: 6,
  decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle,
  boxShadow: [BoxShadow(color: Color(0x884ADE80), blurRadius: 6, spreadRadius: 2)]))),
  const SizedBox(width: 5),
  const Text('System Online', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
  ])));
  Widget _pill(String label, String value) => ClipRRect(
  borderRadius: BorderRadius.circular(11),
  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
  borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white.withOpacity(0.25))),
  child: Column(mainAxisSize: MainAxisSize.min, children: [
  Text(value, style: const TextStyle(color: Colors.white, fontSize: 17,
  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
  Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w500)),
  ]))));
  }

// ── BlockchainStatusBar ──────────────────────────────────────
      class BlockchainStatusBar extends StatelessWidget {
  final DC C; final Animation<double> pulse; final VoidCallback onViewTap;
  const BlockchainStatusBar({super.key, required this.C, required this.pulse, required this.onViewTap});
  @override
  Widget build(BuildContext context) => GlassCard(tint: const Color(0xFFF0FDF4), radius: 16,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: LayoutBuilder(builder: (_, c) {
  final narrow = c.maxWidth < 340;
  return Row(children: [
  AnimatedBuilder(animation: pulse, builder: (_, __) => Transform.scale(scale: pulse.value,
  child: Container(width: 9, height: 9,
  decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle,
  boxShadow: [BoxShadow(color: Color(0x8822C55E), blurRadius: 8, spreadRadius: 3)])))),
  const SizedBox(width: 8),
  const Icon(Icons.link_rounded, size: 16, color: Color(0xFF059669)),
  const SizedBox(width: 6),
  Expanded(child: Text(narrow ? 'Polygon Amoy · Active' : 'Polygon Amoy Testnet  ·  Blockchain active',
  style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600))),
  if (!narrow) ...[
  _chip('Polygon Amoy', const Color(0xFF7C3AED)),
  const SizedBox(width: 6),
  _chip('5 min', const Color(0xFF059669)),
  const SizedBox(width: 10),
  ],
  GestureDetector(onTap: onViewTap,
  child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
  decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1),
  borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF059669).withOpacity(0.25))),
  child: const Text('View Chain', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w700)))),
  ]);
  }));
  Widget _chip(String v, Color c) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  decoration: BoxDecoration(color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(8),
  border: Border.all(color: c.withOpacity(0.2))),
  child: Text(v, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)));
  }

// ── LogoutDialog ─────────────────────────────────────────────
      class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});
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
  boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 16))]),
  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
  Container(width: 42, height: 42,
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
  color: const Color(0xFFEF4444).withOpacity(0.1)),
  child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20)),
  const SizedBox(height: 12),
  const Text('Confirm Logout', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800)),
  const SizedBox(height: 5),
  const Text('Are you sure you want to log out?', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
  const SizedBox(height: 20),
  Row(children: [
  Expanded(child: GestureDetector(onTap: () => Navigator.pop(context, false),
  child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
  decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(11),
  border: Border.all(color: Colors.white.withOpacity(0.8))),
  child: const Center(child: Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)))))),
  const SizedBox(width: 10),
  Expanded(child: GestureDetector(onTap: () => Navigator.pop(context, true),
  child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
  decoration: BoxDecoration(
  gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
  borderRadius: BorderRadius.circular(11),
  boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
  child: const Center(child: Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
  ]),
  ])))));
  }

// ── Shimmer rows ─────────────────────────────────────────────
      List<Widget> shimmerRows(DC C, int count) => List.generate(count, (_) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(children: [
  Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
  const SizedBox(width: 10),
  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Container(height: 11, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
  const SizedBox(height: 5),
  Container(height: 10, width: 130, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
  ])),
  ])));

// ── Error row ─────────────────────────────────────────────────
  Widget errorRow(DC C, String msg, VoidCallback onRetry) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10),
  border: Border.all(color: const Color(0xFFFECACA))),
  child: Row(children: [
  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 14),
  const SizedBox(width: 8),
  Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12))),
  GestureDetector(onTap: onRetry,
  child: const Text('Retry', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.w600))),
  ]));