import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';
import '../models/child.dart';
import '../models/reading_plan.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final _avatarColors = [
    const Color(0xFF6C63FF),
    const Color(0xFF00BFA6),
    const Color(0xFFFF8A65),
    const Color(0xFFFFD54F),
    const Color(0xFF90CAF9),
    const Color(0xFFCE93D8),
  ];

  @override
  Widget build(BuildContext context) {
    final childBox = Hive.box<Child>('children');
    final bookBox = Hive.box<Book>('books');
    final planBox = Hive.box<ReadingPlan>('plans');

    return ValueListenableBuilder(
      valueListenable: childBox.listenable(),
      builder: (context, Box<Child> childListenable, _) {
        final children = childListenable.values.toList(growable: false);
        final childLookup = {
          for (final child in children) child.id: child,
        };

        return ValueListenableBuilder(
          valueListenable: bookBox.listenable(),
          builder: (context, Box<Book> bookListenable, _) {
            final books = bookListenable.values.toList(growable: false);
            final readBooks = books.where((book) => book.readDate != null).toList();

            return ValueListenableBuilder(
              valueListenable: planBox.listenable(),
              builder: (context, Box<ReadingPlan> planListenable, _) {
                final plans = planListenable.values.toList(growable: false);

                final totalPlanCount = plans.length;
                final completedPlanCount = plans.where((plan) => plan.progress >= 1.0).length;
                final activePlanCount = totalPlanCount - completedPlanCount;
                final totalChildren = children.length;

                ReadingPlan? nextUpcomingPlan;
                for (final plan in plans) {
                  if (plan.targetDate == null || plan.progress >= 1.0) continue;
                  if (nextUpcomingPlan == null ||
                      plan.targetDate!.isBefore(nextUpcomingPlan!.targetDate!)) {
                    nextUpcomingPlan = plan;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text(
                      '가족 독서 요약',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _OverviewCards(
                      totalChildren: totalChildren,
                      totalBooks: books.length,
                      readBooks: readBooks.length,
                      activePlans: activePlanCount,
                      completedPlans: completedPlanCount,
                    ),
                    const SizedBox(height: 24),
                    if (children.isEmpty)
                      const _EmptyChildrenCallout()
                    else ...[
                      Text(
                        '자녀별 현황',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...children.map((child) {
                        final childBooks = books
                            .where((book) => book.childId == child.id)
                            .toList(growable: false);
                        final childReadCount = childBooks
                            .where((book) => book.readDate != null)
                            .length;
                        final childPlans = plans
                            .where((plan) => plan.childId == child.id)
                            .toList(growable: false);
                        final childCompletedPlans = childPlans
                            .where((plan) => plan.progress >= 1.0)
                            .length;
                        final childActivePlans = childPlans.length - childCompletedPlans;

                        final childNextPlan = childPlans
                            .where((plan) => plan.targetDate != null && plan.progress < 1.0)
                            .fold<ReadingPlan?>(
                              null,
                              (previous, element) {
                                if (previous == null) return element;
                                return element.targetDate!.isBefore(previous.targetDate!)
                                    ? element
                                    : previous;
                              },
                            );

                        final color = _avatarColors[child.avatarSeed % _avatarColors.length];

                        return _ChildSnapshotCard(
                          child: child,
                          totalBooks: childBooks.length,
                          readBooks: childReadCount,
                          activePlans: childActivePlans,
                          completedPlans: childCompletedPlans,
                          nextPlan: childNextPlan,
                          displayColor: color,
                        );
                      })
                    ],
                    const SizedBox(height: 24),
                    _UpcomingPlanCard(
                      plan: nextUpcomingPlan,
                      childLookup: childLookup,
                    ),
                    const SizedBox(height: 24),
                    const _AiAssistantCard(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({
    required this.totalChildren,
    required this.totalBooks,
    required this.readBooks,
    required this.activePlans,
    required this.completedPlans,
  });

  final int totalChildren;
  final int totalBooks;
  final int readBooks;
  final int activePlans;
  final int completedPlans;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _SummaryTile(
        icon: Icons.family_restroom,
        label: '등록된 자녀',
        value: '$totalChildren명',
        color: Colors.indigo.shade100,
      ),
      _SummaryTile(
        icon: Icons.menu_book,
        label: '전체 등록 도서',
        value: '$totalBooks권',
        color: Colors.orange.shade100,
      ),
      _SummaryTile(
        icon: Icons.check_circle_outline,
        label: '읽은 책',
        value: '$readBooks권',
        color: Colors.green.shade100,
      ),
      _SummaryTile(
        icon: Icons.event_available,
        label: '진행 중 계획',
        value: '$activePlans건',
        color: Colors.purple.shade100,
      ),
      _SummaryTile(
        icon: Icons.emoji_events_outlined,
        label: '완료한 계획',
        value: '$completedPlans건',
        color: Colors.teal.shade100,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChildrenCallout extends StatelessWidget {
  const _EmptyChildrenCallout();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '아직 자녀 프로필이 없어요',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('자녀 탭에서 자녀를 등록하고 독서 계획을 시작해 보세요.'),
          ],
        ),
      ),
    );
  }
}

class _ChildSnapshotCard extends StatelessWidget {
  const _ChildSnapshotCard({
    required this.child,
    required this.totalBooks,
    required this.readBooks,
    required this.activePlans,
    required this.completedPlans,
    required this.nextPlan,
    required this.displayColor,
  });

  final Child child;
  final int totalBooks;
  final int readBooks;
  final int activePlans;
  final int completedPlans;
  final ReadingPlan? nextPlan;
  final Color displayColor;

  @override
  Widget build(BuildContext context) {
    final nextPlanLabel = nextPlan == null
        ? '다가오는 계획 없음'
        : '${nextPlan!.title} · ${nextPlan!.targetDate != null ? DateFormat('MM/dd').format(nextPlan!.targetDate!) : '목표일 미정'}';
    final avatarInitial = child.name.isNotEmpty
        ? child.name.characters.first
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: displayColor,
                  child: Text(
                    avatarInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '누적 독서 $readBooks / $totalBooks권',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ChildMetricChip(icon: Icons.auto_stories, label: '보유 도서', value: '$totalBooks권'),
                _ChildMetricChip(icon: Icons.check, label: '읽은 도서', value: '$readBooks권'),
                _ChildMetricChip(icon: Icons.event, label: '진행 중 계획', value: '$activePlans건'),
                _ChildMetricChip(icon: Icons.emoji_events, label: '완료 계획', value: '$completedPlans건'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nextPlanLabel,
                      style: const TextStyle(color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildMetricChip extends StatelessWidget {
  const _ChildMetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _UpcomingPlanCard extends StatelessWidget {
  const _UpcomingPlanCard({required this.plan, required this.childLookup});

  final ReadingPlan? plan;
  final Map<String, Child> childLookup;

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('다가오는 독서 계획이 없습니다.'),
              SizedBox(height: 8),
              Text('새로운 목표를 계획 탭에서 등록해 보세요.',
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    final child = childLookup[plan!.childId];
    final targetDate = plan!.targetDate != null
        ? DateFormat('yyyy년 MM월 dd일').format(plan!.targetDate!)
        : '목표일 미정';

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('다가오는 독서 계획',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(plan!.title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('자녀: ${child?.name ?? '미배정'}'),
            Text('목표일: $targetDate'),
            if (plan!.bookTitle != null) Text('책: ${plan!.bookTitle}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: plan!.progress.clamp(0.0, 1.0),
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text('진행률 ${(plan!.progress * 100).round()}%'),
          ],
        ),
      ),
    );
  }
}

class _AiAssistantCard extends StatelessWidget {
  const _AiAssistantCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI 독서 도우미',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('자녀별 독서 패턴을 분석해 맞춤형 추천을 준비 중입니다.'),
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
              label: const Text('AI 도우미 미리보기'),
            ),
          ],
        ),
      ),
    );
  }
}
