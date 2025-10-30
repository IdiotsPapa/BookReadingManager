import 'package:flutter/material.dart';
import 'book_list_page.dart';
import 'book_register_page.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("책 관리"),
        centerTitle: true,
      ),
      body: const BookListPage(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 책 등록 후 돌아올 때 setState로 갱신
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookRegisterPage()),
          );
          setState(() {});
        },
        label: const Text("책 등록"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
