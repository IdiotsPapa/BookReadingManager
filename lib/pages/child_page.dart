import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/book.dart';
import '../models/child.dart';
import '../models/reading_plan.dart';

class ChildPage extends StatefulWidget {
  const ChildPage({super.key});

  @override
  State<ChildPage> createState() => _ChildPageState();
}

class _ChildPageState extends State<ChildPage> {
  late final Box<Child> _childBox;
  late final Box<Book> _bookBox;
  late final Box<ReadingPlan> _planBox;
  static const _parentId = 'primary-parent';

  final List<Color> _avatarColors = const [
    Color(0xFF6C63FF),
    Color(0xFF00BFA6),
    Color(0xFFFF8A65),
    Color(0xFFFFD54F),
    Color(0xFF90CAF9),
    Color(0xFFCE93D8),
  ];

  @override
  void initState() {
    super.initState();
    _childBox = Hive.box<Child>('children');
    _bookBox = Hive.box<Book>('books');
    _planBox = Hive.box<ReadingPlan>('plans');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: _childBox.listenable(),
        builder: (context, Box<Child> box, _) {
          final children = box.values.toList(growable: false);

          if (children.isEmpty) {
            return _EmptyState(onAddPressed: () => _showChildForm());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return _ChildCard(
                child: child,
                color: _avatarColors[child.avatarSeed % _avatarColors.length],
                onEdit: () => _showChildForm(child: child),
                onDelete: () => _confirmDelete(child),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChildForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('자녀 등록'),
      ),
    );
  }

  Future<void> _showChildForm({Child? child}) async {
    final nameController = TextEditingController(text: child?.name ?? '');
    final ageController = TextEditingController(
      text: child?.age != null ? child!.age.toString() : '',
    );
    final gradeController = TextEditingController(text: child?.grade ?? '');
    final interestsController = TextEditingController(
      text: child?.interests.join(', ') ?? '',
    );

    final formKey = GlobalKey<FormState>();
    var avatarIndex = child?.avatarSeed ?? 0;

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
                        child == null ? '자녀 등록' : '자녀 정보 수정',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이름을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '나이',
                          hintText: '예: 10',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: gradeController,
                        decoration: const InputDecoration(
                          labelText: '학년 / 반',
                          hintText: '예: 초등학교 3학년',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: interestsController,
                        decoration: const InputDecoration(
                          labelText: '관심사',
                          hintText: '예: 과학, 추리 소설',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '아바타 색상',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_avatarColors.length, (index) {
                          final color = _avatarColors[index];
                          final isSelected = index == avatarIndex;
                          return GestureDetector(
                            onTap: () => setSheetState(() {
                              avatarIndex = index;
                            }),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: Border.all(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white)
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final ageText = ageController.text.trim();
                            final parsedAge = int.tryParse(ageText);
                            final interestsText =
                                interestsController.text.trim();
                            final interests = interestsText.isEmpty
                                ? <String>[]
                                : interestsText
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((element) => element.isNotEmpty)
                                    .toList();

                            if (child == null) {
                              final newChild = Child(
                                id: _generateId(),
                                parentId: _parentId,
                                name: nameController.text.trim(),
                                age: parsedAge,
                                grade: gradeController.text.trim().isEmpty
                                    ? null
                                    : gradeController.text.trim(),
                                interests: interests,
                                avatarSeed: avatarIndex,
                              );
                              await _childBox.add(newChild);
                            } else {
                              child
                                ..name = nameController.text.trim()
                                ..age = parsedAge
                                ..grade = gradeController.text.trim().isEmpty
                                    ? null
                                    : gradeController.text.trim()
                                ..interests = interests
                                ..avatarSeed = avatarIndex
                                ..updatedAt = DateTime.now();
                              await child.save();
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    child == null
                                        ? '자녀 프로필이 등록되었습니다.'
                                        : '자녀 프로필이 수정되었습니다.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(child == null ? '등록하기' : '저장하기'),
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

    nameController.dispose();
    ageController.dispose();
    gradeController.dispose();
    interestsController.dispose();
  }

  Future<void> _confirmDelete(Child child) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자녀 프로필 삭제'),
        content: Text('정말로 ${child.name} 프로필을 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      final booksToUpdate = _bookBox.values
          .where((book) => book.childId == child.id)
          .toList(growable: false);
      for (final book in booksToUpdate) {
        book
          ..childId = null
          ..updatedAt = DateTime.now();
        await book.save();
      }

      final plansToRemove = _planBox.values
          .where((plan) => plan.childId == child.id)
          .toList(growable: false);
      for (final plan in plansToRemove) {
        await plan.delete();
      }

      await child.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${child.name} 프로필이 삭제되었습니다.')),
        );
      }
    }
  }

  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(1 << 32);
    return 'child-$timestamp-$randomSuffix';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom_outlined,
              size: 72, color: Colors.indigo.shade200),
          const SizedBox(height: 24),
          Text(
            '가족 프로필을 등록해 보세요',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '자녀 정보를 등록하면 자녀별 독서 계획과 기록을 관리할 수 있어요.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('자녀 등록하기'),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final Child child;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final interests = child.interests;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color,
                  child: Text(
                    child.name.isNotEmpty ? child.name.characters.first : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
                      if (child.grade != null)
                        Text('학년: ${child.grade}',
                            style: const TextStyle(color: Colors.black54)),
                      if (child.age != null)
                        Text('나이: ${child.age}세',
                            style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                )
              ],
            ),
            if (interests.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests
                    .map(
                      (interest) => Chip(
                        label: Text(interest),
                        backgroundColor: Colors.indigo.shade50,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
