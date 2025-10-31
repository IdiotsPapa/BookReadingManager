import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _MenuCard(
          icon: Icons.person_outline,
          title: '사용자 정보',
          subtitle: '사용자 프로필과 기본 정보를 확인해요.',
        ),
        _MenuCard(
          icon: Icons.settings_outlined,
          title: '앱 설정',
          subtitle: '앱 사용 환경을 조정할 수 있어요.',
        ),
        _MenuCard(
          icon: Icons.cloud_upload_outlined,
          title: '데이터 백업 / 복원',
          subtitle: '데이터를 안전하게 백업하고 복원할 수 있어요.',
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
