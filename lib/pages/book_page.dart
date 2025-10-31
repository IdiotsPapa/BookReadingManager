import 'package:flutter/material.dart';
import 'book_list_page.dart';
import 'book_register_page.dart';

class BookPage extends StatelessWidget {
  const BookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _MenuCard(
          icon: Icons.library_books_outlined,
          title: '책 목록',
          subtitle: '등록된 책을 확인하고 관리해요.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookListPage()),
            );
          },
        ),
        _MenuCard(
          icon: Icons.chrome_reader_mode_outlined,
          title: '책 상세보기',
          subtitle: '책 목록에서 책을 선택해 자세한 정보를 확인할 수 있어요.',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('책 목록에서 책을 선택하면 상세 정보를 볼 수 있어요.'),
              ),
            );
          },
        ),
        _MenuCard(
          icon: Icons.add_circle_outline,
          title: '책 등록 (OCR 기능 포함)',
          subtitle: '새로운 책을 서재에 추가해요.',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookRegisterPage()),
            );
          },
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
