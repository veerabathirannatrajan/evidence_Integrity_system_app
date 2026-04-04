// dashboard_scaffold.dart
// Shared responsive scaffold used by ALL role dashboards.
// KEY FIX: Uses GlobalKey<ScaffoldState> so Scaffold.of() context bug never occurs.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'dashboard_widgets.dart';

/// Build the premium responsive scaffold.
/// Pass role-specific content via [body].
Widget buildDashboardScaffold({
  required String role,
  required String email,
  required String title,
  required bool sidebarExpanded,
  required VoidCallback onToggleSidebar,
  required VoidCallback onRefresh,
  required List<Map<String, dynamic>> navItems,
  required void Function(String) onNavTap,
  required VoidCallback onLogout,
  required ThemeProvider theme,
  required Widget body,
  // GlobalKey so we can open drawer without Scaffold.of() context issues
  required GlobalKey<ScaffoldState> scaffoldKey,
}) {
  return LayoutBuilder(builder: (_, constraints) {
    final w        = constraints.maxWidth;
    final isMobile = w < kMobile;
    final isTablet = w >= kMobile && w < kTablet;
    final C        = DC(false);

    // On mobile/tablet we always pass expanded=false to sidebar in drawer
    final sidebarExp = isMobile ? false : (isTablet ? false : sidebarExpanded);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFEEF2FF),
      // Drawer for mobile — uses GlobalKey to open, no Scaffold.of() needed
      drawer: isMobile
          ? Drawer(
        backgroundColor: Colors.transparent,
        child: DashboardSidebar(
          C: C, expanded: true, role: role, email: email,
          navItems: navItems,
          onNavTap: (s) {
            scaffoldKey.currentState?.closeDrawer();
            onNavTap(s);
          },
          onLogout: onLogout,
        ),
      )
          : null,
      body: Stack(children: [
        // Animated gradient background
        Positioned.fill(child: GlassBackground(role: role)),
        SafeArea(
          child: Row(children: [
            // Sidebar for tablet + desktop
            if (!isMobile)
              DashboardSidebar(
                C: C,
                expanded: sidebarExp,
                role: role, email: email,
                navItems: navItems,
                onNavTap: onNavTap,
                onLogout: onLogout,
              ),
            // Main area
            Expanded(child: Column(children: [
              // AppBar — uses GlobalKey to open drawer on mobile
              DashboardAppBar(
                C: C,
                title: title,
                sidebarExpanded: sidebarExpanded,
                onMenuTap: () {
                  if (isMobile) {
                    scaffoldKey.currentState?.openDrawer();
                  } else {
                    onToggleSidebar();
                  }
                },
                onRefresh: onRefresh,
                theme: theme,
                role: role,
              ),
              // Body content
              Expanded(child: body),
            ])),
          ]),
        ),
      ]),
    );
  });
}