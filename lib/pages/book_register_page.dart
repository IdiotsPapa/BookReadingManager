import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/child.dart';

class BookRegisterPage extends StatefulWidget {
  const BookRegisterPage({Key? key}) : super(key: key);

  @override
  State<BookRegisterPage> createState() => _BookRegisterPageState();
}

class _BookRegisterPageState extends State<BookRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isbnController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _tagsController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedChildId;
  late final Box<Child> _childBox;

  @override
  void initState() {
    super.initState();
    _childBox = Hive.box<Child>('children');
  }

  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<Book>('books');

      final newBook = Book(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        isbn: _isbnController.text.trim().isNotEmpty
            ? _isbnController.text.trim()
            : null,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        readDate: _selectedDate,
        tags: _tagsController.text.isNotEmpty
            ? _tagsController.text.split(',').map((tag) => tag.trim()).toList()
            : [],
        note: _noteController.text.trim(),
        childId: _selectedChildId,
      );

      await box.add(newBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('책이 성공적으로 등록되었습니다!')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책 등록'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_titleController, '제목', '책 제목을 입력하세요'),
              _buildTextField(_authorController, '저자', '저자를 입력하세요'),
              _buildTextField(
                  _descriptionController, '설명', '책에 대한 간단한 설명을 입력하세요',
                  maxLines: 3),
              _buildChildSelector(),
              _buildTextField(_isbnController, 'ISBN', 'ISBN 번호를 입력하세요'),
              _buildTextField(
                  _imageUrlController, '이미지 URL', '책 표지 이미지 URL을 입력하세요'),
              _buildDatePicker(),
              _buildTextField(
                  _tagsController, '태그', '쉼표(,)로 구분하여 입력하세요 (예: 심리, 자기계발)'),
              _buildTextField(_noteController, '메모', '책에 대한 개인 메모를 입력하세요',
                  maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveBook,
                icon: const Icon(Icons.save),
                label: const Text('등록하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if ((label == '제목' || label == '저자') &&
              (value == null || value.trim().isEmpty)) {
            return '$label을(를) 입력해주세요.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildChildSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ValueListenableBuilder(
        valueListenable: _childBox.listenable(),
        builder: (context, Box<Child> box, _) {
          final children = box.values.toList(growable: false);

          if (children.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '연결할 자녀가 없습니다. 자녀 탭에서 먼저 프로필을 등록해주세요.',
                style: TextStyle(color: Colors.black87),
              ),
            );
          }

          final selectedValue = children.any((child) => child.id == _selectedChildId)
              ? _selectedChildId
              : null;

          return DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: const InputDecoration(
              labelText: '독서를 관리할 자녀 선택',
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
              setState(() {
                _selectedChildId = value;
              });
            },
            validator: (value) {
              if (children.isNotEmpty && value == null) {
                return '자녀를 선택해주세요.';
              }
              return null;
            },
          );
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedDate == null
                  ? '읽은 날짜를 선택하세요'
                  : '읽은 날짜: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
            ),
          ),
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: const Text('날짜 선택'),
          ),
        ],
      ),
    );
  }
}
