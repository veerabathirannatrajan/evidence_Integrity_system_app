// dashboard_widgets.dart
// Shared widgets used by all role-specific dashboard files.
// Import this in every role dashboard.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';

// ── Color palette ─────────────────────────────────────────────
class DC {
  final bool isDark;
  DC(this.isDark);
  Color get bg         => isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF0F4FF);
  Color get sidebar    => isDark ? const Color(0xFF0D1320) : Colors.white;
  Color get card       => isDark ? const Color(0xFF111827) : Colors.white;
  Color get inputBg    => isDark ? const Color(0xFF1A2540) : const Color(0xFFF8FAFF);
  Color get border     => isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0);
  Color get txtPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get txtSecond  => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get txtMuted   => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
  Color get accent     => const Color(0xFF2563EB);
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
  'police'     => const Color(0xFF2563EB),
  'forensic'   => const Color(0xFF7C3AED),
  'prosecutor' => const Color(0xFF059669),
  'defense'    => const Color(0xFF0284C7),
  'court'      => const Color(0xFFD97706),
  _            => const Color(0xFF2563EB),
};

IconData roleIcon(String r) => switch (r) {
  'police'     => Icons.local_police_outlined,
  'forensic'   => Icons.biotech_outlined,
  'prosecutor' => Icons.gavel_outlined,
  'defense'    => Icons.balance_outlined,
  'court'      => Icons.account_balance_outlined,
  _            => Icons.person_outline,
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

// ── Shared AppBar ─────────────────────────────────────────────
class DashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final DC C;
  final String title;
  final bool sidebarExpanded;
  final VoidCallback onMenuTap;
  final VoidCallback onRefresh;
  final ThemeProvider theme;
  final String role;

  const DashboardAppBar({
    super.key,
    required this.C,
    required this.title,
    required this.sidebarExpanded,
    required this.onMenuTap,
    required this.onRefresh,
    required this.theme,
    required this.role,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: kToolbarHeight,
          color: C.card,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(children: [
            // Menu toggle
            _iconBtn(C, icon: sidebarExpanded
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
                onTap: onMenuTap),
            const SizedBox(width: 16),
            Text(title,
                style: TextStyle(color: C.txtPrimary,
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            // Refresh
            _iconBtn(C, icon: Icons.refresh_rounded,
                onTap: onRefresh),
            const SizedBox(width: 10),
            // Theme toggle
            _ThemeToggle(C: C, theme: theme),
            const SizedBox(width: 10),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: roleColor(role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: roleColor(role).withOpacity(0.3))),
              child: Row(children: [
                Icon(roleIcon(role),
                    size: 12, color: roleColor(role)),
                const SizedBox(width: 5),
                Text(roleLabel(role),
                    style: TextStyle(color: roleColor(role),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        Divider(color: C.border, height: 1),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final DC C;
  final ThemeProvider theme;
  const _ThemeToggle({required this.C, required this.theme});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: theme.toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: 62, height: 32,
          decoration: BoxDecoration(
              color: theme.isDark
                  ? const Color(0xFF1E3A5F)
                  : const Color(0xFFE0EAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.isDark
                      ? C.accent.withOpacity(0.4)
                      : const Color(0xFF93C5FD))),
          child: Stack(alignment: Alignment.center, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.wb_sunny_rounded, size: 12,
                    color: theme.isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFF59E0B)),
                Icon(Icons.nights_stay_rounded, size: 12,
                    color: theme.isDark
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF94A3B8)),
              ],
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              alignment: theme.isDark
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 26, height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                    color: theme.isDark ? C.accent : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2))]),
                child: Icon(
                    theme.isDark
                        ? Icons.nights_stay_rounded
                        : Icons.wb_sunny_rounded,
                    size: 12,
                    color: theme.isDark
                        ? Colors.white : const Color(0xFFF59E0B)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Shared Sidebar ────────────────────────────────────────────
class DashboardSidebar extends StatefulWidget {
  final DC C;
  final bool expanded;
  final String role;
  final String email;
  final List<Map<String, dynamic>> navItems;
  final void Function(String screen) onNavTap;
  final VoidCallback onLogout;

  const DashboardSidebar({
    super.key,
    required this.C,
    required this.expanded,
    required this.role,
    required this.email,
    required this.navItems,
    required this.onNavTap,
    required this.onLogout,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  int _hovered = -1;

  @override
  Widget build(BuildContext context) {
    final C        = widget.C;
    final expanded = widget.expanded;
    final w        = expanded ? 228.0 : 64.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      width: w,
      decoration: BoxDecoration(
          color: C.sidebar,
          border: Border(right: BorderSide(color: C.border))),
      child: Column(children: [
        // Logo
        SizedBox(height: 62,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: C.accent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(
                          color: C.accent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4))]),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 18),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EvidenceChain',
                          style: TextStyle(color: C.txtPrimary,
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      Text('Blockchain System',
                          style: TextStyle(color: C.accent,
                              fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ]),
            )),

        Divider(color: C.border, height: 1),

        // User chip
        if (expanded)
          _userChip(C, widget.email, widget.role)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CircleAvatar(radius: 14,
                backgroundColor: C.accent,
                child: Text(
                    widget.email.isNotEmpty
                        ? widget.email[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w700))),
          ),

        const SizedBox(height: 4),

        // Nav items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            itemCount: widget.navItems.length,
            itemBuilder: (_, i) {
              final item      = widget.navItems[i];
              final isSection = item['section'] == true;

              if (isSection) {
                return expanded
                    ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                        8, 12, 8, 4),
                    child: Text(item['label'] as String,
                        style: TextStyle(
                            color: C.txtMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)))
                    : const SizedBox.shrink();
              }

              final hover = _hovered == i;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hovered = i),
                onExit:  (_) => setState(() => _hovered = -1),
                child: GestureDetector(
                  onTap: () =>
                      widget.onNavTap(item['screen'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: EdgeInsets.symmetric(
                        horizontal: expanded ? 12 : 16,
                        vertical: 10),
                    decoration: BoxDecoration(
                        color: hover
                            ? C.accent.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9)),
                    child: Row(
                      mainAxisAlignment: expanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Icon(item['icon'] as IconData,
                            size: 17,
                            color: hover ? C.accent : C.txtSecond),
                        if (expanded) ...[
                          const SizedBox(width: 11),
                          Text(item['label'] as String,
                              style: TextStyle(
                                  color: hover ? C.accent : C.txtSecond,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Divider(color: C.border, height: 1),

        // Logout
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onLogout,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: EdgeInsets.symmetric(
                  horizontal: expanded ? 12 : 16,
                  vertical: 10),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded,
                      size: 17, color: Color(0xFFEF4444)),
                  if (expanded) ...[
                    const SizedBox(width: 11),
                    const Text('Logout',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _userChip(DC C, String email, String role) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: C.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.border)),
      child: Row(children: [
        CircleAvatar(radius: 14,
            backgroundColor: C.accent,
            child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email.split('@').first,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: C.txtPrimary,
                    fontSize: 11, fontWeight: FontWeight.w600)),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: roleColor(role).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(roleLabel(role),
                  style: TextStyle(
                      color: roleColor(role),
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        )),
      ]),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────
class StatCard extends StatefulWidget {
  final DC C;
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.C,
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C     = widget.C;
    final color = widget.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: _hovered
                      ? color.withOpacity(0.45) : C.border,
                  width: _hovered ? 1.5 : 1),
              boxShadow: _hovered ? [BoxShadow(
                  color: color.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6))] : []),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                            color: color.withOpacity(
                                C.isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(9)),
                        child: widget.loading
                            ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: color, strokeWidth: 2))
                            : Icon(widget.icon,
                            size: 19, color: color)),
                    Icon(Icons.open_in_new_rounded,
                        size: 12,
                        color: _hovered ? color : C.txtMuted),
                  ]),
              const SizedBox(height: 14),
              widget.loading
                  ? Container(height: 26, width: 60,
                  decoration: BoxDecoration(
                      color: C.inputBg,
                      borderRadius: BorderRadius.circular(4)))
                  : Text(widget.value,
                  style: TextStyle(
                      color: C.txtPrimary,
                      fontSize: widget.value.length > 6
                          ? 18 : 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(widget.label,
                  style: TextStyle(color: C.txtSecond,
                      fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(widget.sub,
                  style: TextStyle(
                      color: C.txtMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────
class ActionCard extends StatefulWidget {
  final DC C;
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.C,
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C     = widget.C;
    final color = widget.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
              color: _hovered
                  ? color.withOpacity(C.isDark ? 0.12 : 0.07)
                  : C.inputBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: _hovered
                      ? color.withOpacity(0.38) : C.border)),
          child: Row(children: [
            Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(widget.icon,
                    size: 14, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: TextStyle(color: C.txtPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(widget.sub,
                    style: TextStyle(color: C.txtSecond,
                        fontSize: 11)),
              ],
            )),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11,
                color: _hovered ? color : C.txtMuted),
          ]),
        ),
      ),
    );
  }
}

// ── Activity Row ──────────────────────────────────────────────
class ActivityRow extends StatelessWidget {
  final DC C;
  final Map<String, dynamic> item;
  final bool isLast;

  const ActivityRow({
    super.key,
    required this.C,
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final type   = item['_type'] as String? ?? 'evidence';
    final isEv   = type == 'evidence';
    final status = item['blockchainStatus'] ?? 'pending';
    final tamper = item['isTampered'] == true;

    Color color;
    IconData icon;
    String title, sub;

    if (isEv) {
      if (tamper) {
        color = const Color(0xFFDC2626);
        icon  = Icons.warning_amber_rounded;
        title = '⚠️ Tamper detected!';
        sub   = item['fileName'] ?? '—';
      } else if (status == 'anchored') {
        color = const Color(0xFF059669);
        icon  = Icons.verified_outlined;
        title = 'Evidence anchored on blockchain';
        sub   = item['fileName'] ?? '—';
      } else {
        color = const Color(0xFF2563EB);
        icon  = Icons.upload_file_outlined;
        title = 'Evidence uploaded';
        sub   = item['fileName'] ?? '—';
      }
    } else {
      color = const Color(0xFF7C3AED);
      icon  = Icons.swap_horiz_rounded;
      title = 'Custody transferred';
      sub   = 'To: ${item['toUser'] ?? '—'}  ·  ${item['reason'] ?? ''}';
    }

    final rawTime = item['createdAt'] ?? item['timestamp'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 15, color: color)),
          if (!isLast)
            Container(width: 1, height: 20,
                color: C.border,
                margin: const EdgeInsets.symmetric(vertical: 3)),
        ]),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: C.txtPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                    Text(timeAgo(rawTime?.toString()),
                        style: TextStyle(
                            color: C.txtMuted, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(sub,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: C.txtSecond, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Blockchain Status Bar ─────────────────────────────────────
class BlockchainStatusBar extends StatelessWidget {
  final DC C;
  final Animation<double> pulse;
  final VoidCallback onViewTap;

  const BlockchainStatusBar({
    super.key,
    required this.C,
    required this.pulse,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: C.border)),
      child: Row(children: [
        AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Transform.scale(
                scale: pulse.value,
                child: Container(width: 7, height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle)))),
        const SizedBox(width: 8),
        Text('Blockchain Connected',
            style: TextStyle(color: C.txtPrimary,
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 18),
        _chip(C, 'Network', 'Polygon Amoy',
            const Color(0xFF7C3AED)),
        const SizedBox(width: 10),
        _chip(C, 'Monitor', 'Every 5 min',
            const Color(0xFF059669)),
        const Spacer(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
              onTap: onViewTap,
              child: Text('View Blockchain →',
                  style: TextStyle(color: C.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600))),
        ),
      ]),
    );
  }

  Widget _chip(DC C, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(C.isDark ? 0.13 : 0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.22))),
      child: Row(children: [
        Text('$label: ',
            style: TextStyle(
                color: color.withOpacity(0.7), fontSize: 11)),
        Text(value,
            style: TextStyle(color: color,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Logout dialog ─────────────────────────────────────────────
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDark;
    final C = DC(isDark);
    return AlertDialog(
      backgroundColor: C.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      title: Text('Confirm Logout',
          style: TextStyle(color: C.txtPrimary,
              fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text('Are you sure you want to log out?',
          style: TextStyle(color: C.txtSecond, fontSize: 13)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: C.txtSecond))),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600))),
      ],
    );
  }
}

// ── Icon button ───────────────────────────────────────────────
Widget _iconBtn(DC C,
    {required IconData icon, required VoidCallback onTap}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: C.inputBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: C.border)),
          child: Icon(icon, size: 16, color: C.txtSecond)),
    ),
  );
}

// ── Shimmer placeholder rows ───────────────────────────────────
List<Widget> shimmerRows(DC C, int count) {
  return List.generate(count, (_) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(width: 32, height: 32,
          decoration: BoxDecoration(
              color: C.inputBg,
              borderRadius: BorderRadius.circular(8))),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 11,
              decoration: BoxDecoration(
                  color: C.inputBg,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(height: 10, width: 150,
              decoration: BoxDecoration(
                  color: C.inputBg,
                  borderRadius: BorderRadius.circular(4))),
        ],
      )),
    ]),
  ));
}

// ── Error row ─────────────────────────────────────────────────
Widget errorRow(DC C, String msg, VoidCallback onRetry) {
  return Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          color: Color(0xFFEF4444), size: 14),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: const TextStyle(
              color: Color(0xFFDC2626), fontSize: 12))),
      GestureDetector(
          onTap: onRetry,
          child: Text('Retry',
              style: TextStyle(color: C.accent,
                  fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );
}