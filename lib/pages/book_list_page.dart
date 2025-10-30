import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import 'book_register_page.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({Key? key}) : super(key: key);

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  late final Box<Book> _bookBox;

  @override
  void initState() {
    super.initState();
    _bookBox = Hive.box<Book>('books');
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
        valueListenable: _bookBox.listenable(),
        builder: (context, Box<Book> box, _) {
          if (box.values.isEmpty) {
            return const Center(child: Text('등록된 책이 없습니다.\n+ 버튼을 눌러 추가하세요.'));
          }

          final books = box.values.toList().cast<Book>();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return _buildBookCard(book);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookCard(Book book) {
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
          _showBookDetailDialog(book);
        },
      ),
    );
  }

  void _showBookDetailDialog(Book book) {
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
