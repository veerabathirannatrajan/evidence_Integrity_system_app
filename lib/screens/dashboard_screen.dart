// dashboard_screen.dart — routing unchanged
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dashboards/police_dashboard.dart';
import 'dashboards/forensic_dashboard.dart';
import 'dashboards/prosecutor_dashboard.dart';
import 'dashboards/defense_dashboard.dart';
import 'dashboards/court_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserProvider>().role ?? 'police';
    if (role == 'forensic')   return const ForensicDashboard();
    if (role == 'prosecutor') return const ProsecutorDashboard();
    if (role == 'defense')    return const DefenseDashboard();
    if (role == 'court')      return const CourtDashboard();
    return const PoliceDashboard();
  }
}