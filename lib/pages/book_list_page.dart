import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
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
  static const List<_CsvColumn> _csvColumns = [
    _CsvColumn(
      key: 'title',
      label: 'title',
      description: '책 제목 (필수)',
    ),
    _CsvColumn(
      key: 'author',
      label: 'author',
      description: '저자명 (필수)',
    ),
    _CsvColumn(
      key: 'description',
      label: 'description',
      description: '책 설명 (선택)',
    ),
    _CsvColumn(
      key: 'isbn',
      label: 'isbn',
      description: 'ISBN 번호 (선택)',
    ),
    _CsvColumn(
      key: 'imageurl',
      label: 'imageUrl',
      description: '책 표지 이미지 URL (선택)',
    ),
    _CsvColumn(
      key: 'readdate',
      label: 'readDate',
      description: '읽은 날짜 (yyyy-MM-dd, 선택)',
    ),
    _CsvColumn(
      key: 'tags',
      label: 'tags',
      description: '태그 목록 (세미콜론 또는 쉼표로 구분, 선택)',
    ),
    _CsvColumn(
      key: 'note',
      label: 'note',
      description: '메모 (선택)',
    ),
    _CsvColumn(
      key: 'childname',
      label: 'childName',
      description: '연결할 자녀 이름 (선택, 기존 등록된 이름과 동일하게)',
    ),
  ];

  static const String _csvSample =
      'title,author,description,isbn,imageUrl,readDate,tags,note,childName\n'
      '"플러터 완벽 가이드","홍길동","2장 읽기","9781234567890","https://example.com/cover.png","2025-01-01","코딩;학습","가족과 함께 읽기","민수"';

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
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'CSV 업로드',
            onPressed: _importFromCsv,
          ),
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

  Future<void> _importFromCsv() async {
    if (!mounted) return;
    final shouldPick = await _showCsvImportGuide();
    if (shouldPick != true || !mounted) {
      return;
    }

    try {
      final typeGroup = XTypeGroup(label: 'CSV', extensions: const ['csv']);
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        return;
      }

      final csvString = await file.readAsString();
      if (csvString.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV 파일을 읽을 수 없습니다. 다시 시도해주세요.')),
        );
        return;
      }
      final rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV 파일에 데이터가 없습니다.')),
        );
        return;
      }

      final headersRaw = rows.first;
      final normalizedHeaders = headersRaw
          .map((cell) => _normalizeHeader(cell?.toString() ?? ''))
          .toList();

      final Map<String, int> headerIndex = {};
      final List<String> missingHeaders = [];

      for (final column in _csvColumns) {
        final normalizedKey = _normalizeHeader(column.key);
        final index = normalizedHeaders.indexOf(normalizedKey);
        if (index == -1) {
          missingHeaders.add(column.label);
        } else {
          headerIndex[column.key] = index;
        }
      }

      if (missingHeaders.isNotEmpty) {
        if (!mounted) return;
        await _showImportIssues([
          '다음 헤더가 누락되었습니다: ${missingHeaders.join(', ')}',
          'CSV 첫 행에 올바른 헤더를 추가한 뒤 다시 시도해주세요.',
        ]);
        return;
      }

      final Map<String, Child> childLookup = {
        for (final child in _childBox.values)
          child.name.trim().toLowerCase(): child,
      };

      final List<String> issues = [];
      int successCount = 0;
      final totalRows = rows.length - 1;

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
          continue;
        }

        String readCell(String key) {
          final index = headerIndex[key];
          if (index == null || index >= row.length) {
            return '';
          }
          final value = row[index];
          if (value == null) {
            return '';
          }
          return value.toString().trim();
        }

        final title = readCell('title');
        final author = readCell('author');

        if (title.isEmpty || author.isEmpty) {
          issues.add('${i + 1}행: 제목 또는 저자가 비어 있어 건너뜁니다.');
          continue;
        }

        final description = readCell('description');
        final isbn = readCell('isbn');
        final imageUrl = readCell('imageurl');
        final readDateRaw = readCell('readdate');
        final tagsRaw = readCell('tags');
        final note = readCell('note');
        final childName = readCell('childname');

        DateTime? readDate;
        if (readDateRaw.isNotEmpty) {
          try {
            readDate = DateFormat('yyyy-MM-dd').parseStrict(readDateRaw);
          } catch (_) {
            issues.add('${i + 1}행: 읽은 날짜 "$readDateRaw" 형식을 해석할 수 없어 미적용됩니다. (yyyy-MM-dd)');
          }
        }

        final tags = tagsRaw.isEmpty
            ? <String>[]
            : tagsRaw
                .split(RegExp(r'[;,]'))
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList();

        Child? child;
        if (childName.isNotEmpty) {
          child = childLookup[childName.toLowerCase()];
          if (child == null) {
            issues.add('${i + 1}행: 자녀 "$childName"을(를) 찾을 수 없어 미배정으로 저장됩니다.');
          }
        }

        final isDuplicate = _bookBox.values.any((existing) =>
            existing.title.trim().toLowerCase() == title.toLowerCase() &&
            existing.author.trim().toLowerCase() == author.toLowerCase() &&
            (existing.childId ?? '') == (child?.id ?? ''));

        if (isDuplicate) {
          issues.add('${i + 1}행: 동일한 제목/저자 조합이 이미 존재하여 건너뜁니다.');
          continue;
        }

        final newBook = Book(
          title: title,
          author: author,
          description: description,
          isbn: isbn.isEmpty ? null : isbn,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          readDate: readDate,
          tags: tags,
          note: note.isNotEmpty ? note : null,
          childId: child?.id,
        );

        await _bookBox.add(newBook);
        successCount++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV 업로드 완료: 총 $totalRows건 중 $successCount건 추가되었습니다.'),
        ),
      );

      if (issues.isNotEmpty) {
        await _showImportIssues(issues);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV 처리 중 오류가 발생했습니다: $error'),
        ),
      );
    }
  }

  Future<bool?> _showCsvImportGuide() {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CSV 업로드 안내',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('• 첫 번째 행에는 아래 헤더 이름을 그대로 입력해주세요.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _csvColumns
                        .map(
                          (column) => Chip(
                            label: Text(column.label),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('• 각 열 설명'),
                  const SizedBox(height: 8),
                  ..._csvColumns.map(
                    (column) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('· ${column.label}: ${column.description}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('• 태그는 세미콜론(;) 또는 쉼표(,)로 구분할 수 있으며, CSV 인코딩은 UTF-8을 권장합니다.'),
                  const SizedBox(height: 16),
                  const Text('예시'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const SelectableText(_csvSample),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('파일 선택'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showImportIssues(List<String> messages) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('업로드 결과 안내'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: messages.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(messages[index]),
            ),
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

  String _normalizeHeader(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]'), '');
  }
}

class _CsvColumn {
  const _CsvColumn({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;
}
