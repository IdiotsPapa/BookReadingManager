import 'package:flutter/material.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _MenuCard(
          icon: Icons.view_list_outlined,
          title: '독서 계획 목록',
          subtitle: '등록된 독서 계획을 살펴봐요.',
        ),
        _MenuCard(
          icon: Icons.description_outlined,
          title: '계획 상세보기',
          subtitle: '계획별 상세 정보를 확인할 수 있어요.',
        ),
        _MenuCard(
          icon: Icons.playlist_add_check_outlined,
          title: '새 계획 등록',
          subtitle: '새로운 독서 계획을 추가해요.',
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
