import 'package:flutter/material.dart';

class QrGeneratorScreen extends StatelessWidget {
  final String evidenceId;
  const QrGeneratorScreen({super.key, required this.evidenceId});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0B0F1A) : const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: dark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('QR Code Generator',
            style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 16, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
                color: dark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
                height: 1)),
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.qr_code_2_rounded,
                size: 38, color: Color(0xFF0284C7)),
          ),
          const SizedBox(height: 20),
          Text('QR Code Generator',
              style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Evidence: $evidenceId',
              style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 12, fontFamily: 'monospace')),
          const SizedBox(height: 6),
          Text('Implementation coming soon',
              style: TextStyle(
                  color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 14)),
        ]),
      ),
    );
  }
}