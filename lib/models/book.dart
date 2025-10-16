import 'package:hive/hive.dart'; // Hive 필수 import

part 'book.g.dart'; // 자동 생성 파일, 반드시 part 사용

@HiveType(typeId: 0)
class Book extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String author;

  @HiveField(2)
  String? isbn;

  @HiveField(3)
  String? imageUrl;

  @HiveField(4)
  DateTime? readDate;

  // 생성자
  Book({
    required this.title,
    required this.author,
    this.isbn,
    this.imageUrl,
    this.readDate,
  });
}
