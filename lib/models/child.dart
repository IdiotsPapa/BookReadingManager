import 'package:hive/hive.dart';

part 'child.g.dart';

/// 👶 Child 모델
/// 부모 계정과 연결된 자녀 프로필 정보를 저장합니다.
@HiveType(typeId: 1)
class Child extends HiveObject {
  /// 고유 식별자 (UUID)
  @HiveField(0)
  String id;

  /// 부모 식별자 (현재는 단일 부모이므로 기본값을 사용)
  @HiveField(1)
  String parentId;

  /// 자녀 이름
  @HiveField(2)
  String name;

  /// 나이 (선택)
  @HiveField(3)
  int? age;

  /// 학년 또는 학급 정보 (선택)
  @HiveField(4)
  String? grade;

  /// 관심사 목록
  @HiveField(5)
  List<String> interests;

  /// 아바타 또는 색상 선택을 위한 인덱스 값
  @HiveField(6)
  int avatarSeed;

  /// 등록 일자
  @HiveField(7)
  DateTime createdAt;

  /// 수정 일자
  @HiveField(8)
  DateTime? updatedAt;

  Child({
    required this.id,
    required this.parentId,
    required this.name,
    this.age,
    this.grade,
    List<String>? interests,
    this.avatarSeed = 0,
    DateTime? createdAt,
    this.updatedAt,
  })  : interests = interests ?? <String>[],
        createdAt = createdAt ?? DateTime.now();

  Child copyWith({
    String? name,
    int? age,
    String? grade,
    List<String>? interests,
    int? avatarSeed,
    DateTime? updatedAt,
  }) {
    return Child(
      id: id,
      parentId: parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      grade: grade ?? this.grade,
      interests: interests ?? List<String>.from(this.interests),
      avatarSeed: avatarSeed ?? this.avatarSeed,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
