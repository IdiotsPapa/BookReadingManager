import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _MenuCard(
          icon: Icons.people_outline,
          title: '사용자별 독서 기록 목록',
          subtitle: '사용자별 기록을 한눈에 살펴봐요.',
        ),
        _MenuCard(
          icon: Icons.calendar_month_outlined,
          title: '일별 / 월별 통계',
          subtitle: '기간별 독서 통계를 확인할 수 있어요.',
        ),
        _MenuCard(
          icon: Icons.stacked_line_chart,
          title: '그래프 시각화',
          subtitle: '독서 기록을 그래프로 표현할 예정이에요.',
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('해당 기능은 준비 중입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showComingSoon(context),
      ),
    );
  }
}
