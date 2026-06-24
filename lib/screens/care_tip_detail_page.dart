import 'package:flutter/material.dart';

import '../data/care_tips_data.dart';

class CareTipDetailPage extends StatelessWidget {
  final CareTip tip;
  const CareTipDetailPage({super.key, required this.tip});

  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _sectionCard(tip.sections[i]),
                ),
                childCount: tip.sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 28),
      decoration: const BoxDecoration(
        color: _brown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18)),
            child: Icon(tip.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(tip.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          Text(tip.summary, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }

  Widget _sectionCard(CareTipSection section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 10),
          Text(section.body, style: const TextStyle(fontSize: 14, color: _mutedBrown, height: 1.6)),
        ],
      ),
    );
  }
}
