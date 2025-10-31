// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadingPlanAdapter extends TypeAdapter<ReadingPlan> {
  @override
  final int typeId = 2;

  @override
  ReadingPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingPlan(
      id: fields[0] as String,
      childId: fields[1] as String,
      title: fields[2] as String,
      bookTitle: fields[3] as String?,
      targetDate: fields[4] as DateTime?,
      progress: (fields[5] as num?)?.toDouble() ?? 0.0,
      note: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingPlan obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.childId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.bookTitle)
      ..writeByte(4)
      ..write(obj.targetDate)
      ..writeByte(5)
      ..write(obj.progress)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
