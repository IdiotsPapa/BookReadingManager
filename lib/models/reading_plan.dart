import 'package:hive/hive.dart';

part 'reading_plan.g.dart';

/// 🗂️ ReadingPlan 모델
/// 자녀별 독서 계획을 저장하고 진행 상황을 추적합니다.
@HiveType(typeId: 2)
class ReadingPlan extends HiveObject {
  /// 고유 식별자 (UUID)
  @HiveField(0)
  String id;

  /// 자녀의 Hive 키
  @HiveField(1)
  String childId;

  /// 계획 제목 (또는 목표)
  @HiveField(2)
  String title;

  /// 계획과 연결된 책 제목 (선택)
  @HiveField(3)
  String? bookTitle;

  /// 목표 완료 날짜
  @HiveField(4)
  DateTime? targetDate;

  /// 진행도 (0.0 ~ 1.0)
  @HiveField(5)
  double progress;

  /// 추가 메모
  @HiveField(6)
  String? note;

  /// 등록 및 수정 시간 기록
  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? updatedAt;

  ReadingPlan({
    required this.id,
    required this.childId,
    required this.title,
    this.bookTitle,
    this.targetDate,
    this.progress = 0,
    this.note,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ReadingPlan copyWith({
    String? title,
    String? bookTitle,
    DateTime? targetDate,
    double? progress,
    String? note,
    DateTime? updatedAt,
  }) {
    return ReadingPlan(
      id: id,
      childId: childId,
      title: title ?? this.title,
      bookTitle: bookTitle ?? this.bookTitle,
      targetDate: targetDate ?? this.targetDate,
      progress: progress ?? this.progress,
      note: note ?? this.note,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
