import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';
import '../models/child.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final Box<Book> _bookBox;
  late final Box<Child> _childBox;
  String? _selectedChildId;

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
    _bookBox = Hive.box<Book>('books');
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
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '자녀별 독서 기록',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (children.isEmpty)
                      const Text(
                        '자녀를 먼저 등록하세요',
                        style: TextStyle(color: Colors.black45),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildChildFilter(children),
                const SizedBox(height: 16),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _bookBox.listenable(),
                    builder: (context, Box<Book> bookBox, _) {
                      final historyBooks = bookBox.values
                          .where((book) => book.readDate != null)
                          .toList(growable: false)
                        ..sort(
                          (a, b) => b.readDate!.compareTo(a.readDate!),
                        );

                      final filteredBooks = _selectedChildId == null
                          ? historyBooks
                          : historyBooks
                              .where((book) => book.childId == _selectedChildId)
                              .toList();

                      final totalCount = filteredBooks.length;
                      final now = DateTime.now();
                      final monthStart = DateTime(now.year, now.month);
                      final thisMonthCount = filteredBooks
                          .where((book) => book.readDate!.isAfter(monthStart) ||
                              book.readDate!.isAtSameMomentAs(monthStart))
                          .length;

                      if (historyBooks.isEmpty) {
                        return const _EmptyHistoryState();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HistorySummary(
                            totalCount: totalCount,
                            thisMonthCount: thisMonthCount,
                            childName: _selectedChildId == null
                                ? '전체 자녀'
                                : childLookup[_selectedChildId!]?.name ?? '미배정',
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: filteredBooks.isEmpty
                                ? Center(
                                    child: Text(
                                      '선택한 자녀의 독서 기록이 없습니다.',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filteredBooks.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final book = filteredBooks[index];
                                      final child = book.childId != null
                                          ? childLookup[book.childId]
                                          : null;
                                      return _HistoryCard(
                                        book: book,
                                        child: child,
                                        avatarColor: child == null
                                            ? Colors.grey.shade300
                                            : _avatarColors[child.avatarSeed %
                                                _avatarColors.length],
                                        onEditDate: () => _editReadDate(book),
                                        onClearDate: () => _clearReadDate(book),
                                      );
                                    },
                                  ),
                          ),
                        ],
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
    if (children.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.indigo.shade50,
        ),
        child: const Text('자녀 탭에서 자녀를 등록하면 기록을 분리해서 볼 수 있어요.'),
      );
    }

    return DropdownButtonFormField<String?>(
      value: _selectedChildId,
      decoration: const InputDecoration(
        labelText: '자녀 선택',
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

  Future<void> _editReadDate(Book book) async {
    final initialDate = book.readDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked != null) {
      book
        ..readDate = picked
        ..updatedAt = DateTime.now();
      await book.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title}의 읽은 날짜가 업데이트되었어요.')),
        );
      }
    }
  }

  Future<void> _clearReadDate(Book book) async {
    book
      ..readDate = null
      ..updatedAt = DateTime.now();
    await book.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title}의 읽은 기록이 초기화되었어요.')),
      );
    }
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.totalCount,
    required this.thisMonthCount,
    required this.childName,
  });

  final int totalCount;
  final int thisMonthCount;
  final String childName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$childName 독서 현황',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryBadge(
                  icon: Icons.auto_stories,
                  label: '총 독서',
                  value: '$totalCount권',
                ),
                _SummaryBadge(
                  icon: Icons.calendar_today,
                  label: '이번 달',
                  value: '$thisMonthCount권',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.book,
    required this.child,
    required this.avatarColor,
    required this.onEditDate,
    required this.onClearDate,
  });

  final Book book;
  final Child? child;
  final Color avatarColor;
  final VoidCallback onEditDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    final readDate = book.readDate != null
        ? DateFormat('yyyy-MM-dd').format(book.readDate!)
        : '날짜 미지정';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Text(
            child != null && child.name.isNotEmpty
                ? child.name.characters.first
                : '미',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(book.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('자녀: ${child?.name ?? '미배정'}'),
            Text('읽은 날짜: $readDate'),
            if (book.note != null && book.note!.isNotEmpty)
              Text('메모: ${book.note!}', maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEditDate();
            } else if (value == 'clear') {
              onClearDate();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('읽은 날짜 수정')),
            PopupMenuItem(value: 'clear', child: Text('기록 초기화')),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.indigo.shade200),
          const SizedBox(height: 24),
          Text(
            '아직 읽은 책이 없어요.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '책을 등록할 때 읽은 날짜와 자녀를 함께 선택하면 기록이 쌓입니다.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
