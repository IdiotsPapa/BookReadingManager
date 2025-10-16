import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  void _addBook() {
    final String title = _titleController.text;
    final String author = _authorController.text;

    if (title.isEmpty || author.isEmpty) return;

    final book = Book(title: title, author: author);
    Hive.box<Book>('books').add(book);

    _titleController.clear();
    _authorController.clear();
    Navigator.of(context).pop();
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("책 추가"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "제목")),
            TextField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: "저자")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("취소")),
          ElevatedButton(onPressed: _addBook, child: const Text("추가")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 서재"),
      ),
      body: ValueListenableBuilder<Box<Book>>(
        valueListenable: Hive.box<Book>('books').listenable(),
        builder: (context, box, _) {
          if (box.values.isEmpty) {
            return const Center(child: Text("등록된 책이 없습니다."));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final book = box.getAt(index);
              return ListTile(
                title: Text(book!.title),
                subtitle: Text(book.author),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => box.deleteAt(index),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
