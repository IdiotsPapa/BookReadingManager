import 'package:hive/hive.dart';

part 'book.g.dart';

/// 📚 Book 모델
/// OCR로 추출된 텍스트 기반 → Google Books API 자동완성 결과와 결합
/// 이후 AI 추천(태그, 요약)까지 반영 가능하도록 확장 설계
@HiveType(typeId: 0)
class Book extends HiveObject {
  /// 책 제목
  @HiveField(0)
  String title;

  /// 저자명
  @HiveField(1)
  String author;

  /// 책 설명 (OCR 또는 Google Books에서 자동 완성)
  @HiveField(2)
  String description;

  /// 국제 표준 도서번호 (ISBN)
  @HiveField(3)
  String? isbn;

  /// 책 표지 이미지 경로 (로컬 경로 or 네트워크 URL)
  @HiveField(4)
  String? imageUrl;

  /// 사용자가 실제 읽은 날짜
  @HiveField(5)
  DateTime? readDate;

  /// OCR 원문 텍스트 (디버깅 및 재처리용)
  @HiveField(6)
  String? ocrText;

  /// AI 또는 Google Books에서 분석된 주요 키워드 태그 목록
  @HiveField(7)
  List<String>? tags;

  /// Google Books API의 식별자 (volumeId)
  @HiveField(8)
  String? googleBookId;

  /// 사용자의 개인 메모 / 코멘트
  @HiveField(9)
  String? note;

  /// 등록 일자 (기록 관리용)
  @HiveField(10)
  DateTime createdAt;

  /// 수정 일자 (자동 갱신)
  @HiveField(11)
  DateTime? updatedAt;

  /// 책을 읽은 자녀 식별자 (부모 - 자녀 매핑 용도)
  @HiveField(12)
  String? childId;

  Book({
    required this.title,
    required this.author,
    this.description = '',
    this.isbn,
    this.imageUrl,
    this.readDate,
    this.ocrText,
    this.tags,
    this.googleBookId,
    this.note,
    DateTime? createdAt,
    this.updatedAt,
    this.childId,
  }) : createdAt = createdAt ?? DateTime.now();
}
