import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          '요약 대시보드',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('오늘의 독서 계획',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Chip(label: Text('진행 중')),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('『플러터 완벽 가이드』 2장 읽기 (40%)'),
                const SizedBox(height: 16),
                const Text('진행률 요약',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.4,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 16),
                const Text('추천 도서',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.auto_awesome, color: Colors.indigo),
                  title:
                      const Text('『생각의 탄생』 - 창의적 사고의 비밀'),
                  subtitle: const Text('AI 챗봇 추천 도서'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI 추천 도서는 곧 업데이트될 예정이에요.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'AI 추천 챗봇',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '독서 취향을 분석하고 맞춤형 도서를 추천해 드릴게요.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI 추천 챗봇 기능은 준비 중입니다.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('AI 추천 챗봇 시작하기'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
