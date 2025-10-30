import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text("📚 오늘의 독서 계획",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text("『플러터 완벽 가이드』 2장 읽기"),
              subtitle: const Text("진행률: 40%"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
          const Text("🎯 진행률 요약",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: 0.4, minHeight: 8, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 16),
          const Text("🤖 AI 추천 도서",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: Colors.indigo.shade50,
            child: ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.indigo),
              title: const Text("『생각의 탄생』 - 창의적 사고의 비밀"),
              subtitle: const Text("AI 챗봇 추천 도서"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("AI 추천 챗봇 기능은 곧 추가됩니다.")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
