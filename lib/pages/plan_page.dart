import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/child.dart';
import '../models/reading_plan.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late final Box<ReadingPlan> _planBox;
  late final Box<Child> _childBox;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _planBox = Hive.box<ReadingPlan>('plans');
    _childBox = Hive.box<Child>('children');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _childBox.listenable(),
      builder: (context, Box<Child> childBox, _) {
        final children = childBox.values.toList(growable: false);
        final childLookup = {
          for (final child in children) child.id: child,
        };

        if (_selectedChildId != null && !childLookup.containsKey(_selectedChildId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedChildId = null;
            });
          });
        }

        return Scaffold(
          floatingActionButton: children.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showPlanForm(children: children),
                  icon: const Icon(Icons.playlist_add_check_outlined),
                  label: const Text('계획 추가'),
                ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: children.isEmpty
                ? const _EmptyPlanState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChildFilter(children),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _planBox.listenable(),
                          builder: (context, Box<ReadingPlan> planBox, _) {
                            final plans = planBox.values
                                .where((plan) => childLookup.containsKey(plan.childId))
                                .toList(growable: false)
                              ..sort((a, b) {
                                final adate = a.targetDate ?? DateTime(9999);
                                final bdate = b.targetDate ?? DateTime(9999);
                                return adate.compareTo(bdate);
                              });

                            final filteredPlans = _selectedChildId == null
                                ? plans
                                : plans
                                    .where((plan) => plan.childId == _selectedChildId)
                                    .toList();

                            if (filteredPlans.isEmpty) {
                              return Center(
                                child: Text(
                                  _selectedChildId == null
                                      ? '등록된 독서 계획이 없습니다.\n오른쪽 아래 + 버튼으로 추가하세요.'
                                      : '선택한 자녀의 독서 계획이 없습니다.',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredPlans.length,
                              itemBuilder: (context, index) {
                                final plan = filteredPlans[index];
                                final child = childLookup[plan.childId];
                                return _PlanCard(
                                  plan: plan,
                                  child: child!,
                                  onEdit: () => _showPlanForm(
                                    plan: plan,
                                    children: children,
                                  ),
                                  onDelete: () => _deletePlan(plan),
                                  onMarkComplete: () => _markPlanComplete(plan),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildChildFilter(List<Child> children) {
    return DropdownButtonFormField<String?>(
      value: _selectedChildId,
      decoration: const InputDecoration(
        labelText: '자녀별 계획 보기',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('전체 자녀'),
        ),
        ...children.map(
          (child) => DropdownMenuItem<String?>(
            value: child.id,
            child: Text(child.name),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedChildId = value;
        });
      },
    );
  }

  Future<void> _showPlanForm({ReadingPlan? plan, required List<Child> children}) async {
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자녀를 먼저 등록해주세요.')),
      );
      return;
    }

    final titleController = TextEditingController(text: plan?.title ?? '');
    final bookController = TextEditingController(text: plan?.bookTitle ?? '');
    final noteController = TextEditingController(text: plan?.note ?? '');
    var progress = plan?.progress ?? 0.0;
    var targetDate = plan?.targetDate;
    String selectedChildId = plan?.childId ?? _selectedChildId ?? children.first.id;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan == null ? '새 독서 계획' : '독서 계획 수정',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedChildId,
                        decoration: const InputDecoration(
                          labelText: '자녀 선택',
                          border: OutlineInputBorder(),
                        ),
                        items: children
                            .map(
                              (child) => DropdownMenuItem(
                                value: child.id,
                                child: Text(child.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            selectedChildId = value ?? selectedChildId;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: '계획 제목',
                          hintText: '예: 4월 과학 독서 마스터',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '계획 제목을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bookController,
                        decoration: const InputDecoration(
                          labelText: '책 제목 (선택)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TargetDatePicker(
                        targetDate: targetDate,
                        onPick: (date) => setSheetState(() {
                          targetDate = date;
                        }),
                      ),
                      const SizedBox(height: 16),
                      Text('진행도: ${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) => setSheetState(() {
                          progress = value;
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: '메모 (선택)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            if (selectedChildId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('자녀를 선택해주세요.')),
                              );
                              return;
                            }

                            if (plan == null) {
                              final newPlan = ReadingPlan(
                                id: _generateId(),
                                childId: selectedChildId!,
                                title: titleController.text.trim(),
                                bookTitle: bookController.text.trim().isEmpty
                                    ? null
                                    : bookController.text.trim(),
                                targetDate: targetDate,
                                progress: progress,
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                              );
                              await _planBox.add(newPlan);
                            } else {
                              plan
                                ..childId = selectedChildId!
                                ..title = titleController.text.trim()
                                ..bookTitle = bookController.text.trim().isEmpty
                                    ? null
                                    : bookController.text.trim()
                                ..targetDate = targetDate
                                ..progress = progress
                                ..note = noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim()
                                ..updatedAt = DateTime.now();
                              await plan.save();
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    plan == null
                                        ? '독서 계획이 등록되었습니다.'
                                        : '독서 계획이 수정되었습니다.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(plan == null ? '등록하기' : '저장하기'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    titleController.dispose();
    bookController.dispose();
    noteController.dispose();
  }

  Future<void> _deletePlan(ReadingPlan plan) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계획 삭제'),
        content: Text('정말로 "${plan.title}" 계획을 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      await plan.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${plan.title}" 계획이 삭제되었습니다.')),
        );
      }
    }
  }

  Future<void> _markPlanComplete(ReadingPlan plan) async {
    plan
      ..progress = 1.0
      ..updatedAt = DateTime.now();
    await plan.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${plan.title}" 계획이 완료로 표시되었습니다.')),
      );
    }
  }

  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(1 << 32);
    return 'plan-$timestamp-$randomSuffix';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkComplete,
  });

  final ReadingPlan plan;
  final Child child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final targetLabel = plan.targetDate != null
        ? DateFormat('yyyy-MM-dd').format(plan.targetDate!)
        : '목표 날짜 없음';
    final progressPercent = (plan.progress * 100).clamp(0, 100).round();
    final isCompleted = plan.progress >= 1.0;
    final avatarInitial = child.name.isNotEmpty
        ? child.name.characters.first
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(avatarInitial),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '자녀: ${child.name}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        '목표: $targetLabel',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (plan.bookTitle != null && plan.bookTitle!.isNotEmpty)
                        Text('책: ${plan.bookTitle}',
                            style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'complete':
                        onMarkComplete();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정')),
                    if (!isCompleted)
                      const PopupMenuItem(value: 'complete', child: Text('완료 처리')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text(isCompleted ? '완료' : '진행 중'),
                  backgroundColor:
                      isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                ),
                const SizedBox(width: 8),
                Text('진행률 $progressPercent%'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: plan.progress.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            if (plan.note != null && plan.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(plan.note!),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.self_improvement, size: 64, color: Colors.indigo.shade200),
          const SizedBox(height: 24),
          Text(
            '자녀별 독서 계획을 세워볼까요?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '자녀 탭에서 먼저 자녀를 등록하면 계획을 추가할 수 있어요.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TargetDatePicker extends StatelessWidget {
  const _TargetDatePicker({required this.targetDate, required this.onPick});

  final DateTime? targetDate;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    final label = targetDate == null
        ? '목표 날짜를 선택하세요'
        : '목표 날짜: ${DateFormat('yyyy-MM-dd').format(targetDate!)}';

    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: targetDate ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        onPick(picked);
      },
      icon: const Icon(Icons.event_outlined),
      label: Text(label),
    );
  }
}
