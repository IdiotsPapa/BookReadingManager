import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/child.dart';
import 'book_register_page.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({Key? key}) : super(key: key);

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  late final Box<Book> _bookBox;
  late final Box<Child> _childBox;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _bookBox = Hive.box<Book>('books');
    _childBox = Hive.box<Child>('children');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 서재'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '책 등록',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookRegisterPage()),
              );
              setState(() {}); // 돌아오면 새로고침
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildChildFilter(children),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _bookBox.listenable(),
                  builder: (context, Box<Book> bookBox, _) {
                    if (bookBox.values.isEmpty) {
                      return const Center(
                        child: Text('등록된 책이 없습니다.\n+ 버튼을 눌러 추가하세요.'),
                      );
                    }

                    final books = bookBox.values.toList().cast<Book>()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    final filteredBooks = _selectedChildId == null
                        ? books
                        : books
                            .where((book) => book.childId == _selectedChildId)
                            .toList();

                    if (filteredBooks.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedChildId == null
                              ? '등록된 책이 없습니다.\n+ 버튼을 눌러 추가하세요.'
                              : '선택한 자녀의 등록된 책이 없습니다.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        final child = book.childId != null
                            ? childLookup[book.childId]
                            : null;
                        return _buildBookCard(book, child);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
        child: const Text(
          '자녀를 등록하면 자녀별로 서재를 정리할 수 있어요.',
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    return DropdownButtonFormField<String?>(
      value: _selectedChildId,
      decoration: const InputDecoration(
        labelText: '자녀별 필터',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildBookCard(Book book, Child? child) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: (book.imageUrl?.isNotEmpty ?? false)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.imageUrl!,
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.book, size: 40, color: Colors.grey),
                ),
              )
            : const Icon(Icons.book_outlined, size: 40, color: Colors.grey),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author, style: const TextStyle(color: Colors.black54)),
            if (child != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '자녀: ${child.name}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            if (book.readDate != null)
              Text(
                '읽은 날짜: ${DateFormat('yyyy-MM-dd').format(book.readDate!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if ((book.tags?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 6,
                  children: (book.tags ?? [])
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
        onTap: () {
          _showBookDetailDialog(book, child);
        },
      ),
    );
  }

  void _showBookDetailDialog(Book book, Child? child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (book.imageUrl != null && book.imageUrl!.isNotEmpty)
                Center(
                  child: Image.network(
                    book.imageUrl!,
                    height: 180,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.book, size: 80),
                  ),
                ),
              const SizedBox(height: 12),
              Text('저자: ${book.author}'),
              if (book.isbn != null) Text('ISBN: ${book.isbn}'),
              if (child != null) Text('자녀: ${child.name}'),
              const SizedBox(height: 8),
              Text(
                  '설명:\n${book.description.isNotEmpty ? book.description : "설명 없음"}'),
              const SizedBox(height: 8),
              if (book.note != null && book.note!.isNotEmpty)
                Text('메모:\n${book.note!}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
