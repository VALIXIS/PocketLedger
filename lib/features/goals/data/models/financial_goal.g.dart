// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinancialGoalAdapter extends TypeAdapter<FinancialGoal> {
  @override
  final int typeId = 4;

  @override
  FinancialGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinancialGoal(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      targetAmountInCents: fields[3] as int,
      savedAmountInCents: fields[4] as int,
      targetDate: fields[5] as DateTime?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      status: fields[8] as GoalStatus,
      iconName: fields[9] as String,
      colorValue: fields[10] as int,
      userId: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FinancialGoal obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.targetAmountInCents)
      ..writeByte(4)
      ..write(obj.savedAmountInCents)
      ..writeByte(5)
      ..write(obj.targetDate)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.iconName)
      ..writeByte(10)
      ..write(obj.colorValue)
      ..writeByte(11)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalStatusAdapter extends TypeAdapter<GoalStatus> {
  @override
  final int typeId = 6;

  @override
  GoalStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalStatus.active;
      case 1:
        return GoalStatus.completed;
      case 2:
        return GoalStatus.paused;
      case 3:
        return GoalStatus.cancelled;
      default:
        return GoalStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, GoalStatus obj) {
    switch (obj) {
      case GoalStatus.active:
        writer.writeByte(0);
        break;
      case GoalStatus.completed:
        writer.writeByte(1);
        break;
      case GoalStatus.paused:
        writer.writeByte(2);
        break;
      case GoalStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
