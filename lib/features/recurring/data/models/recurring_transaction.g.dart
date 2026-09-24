// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionAdapter extends TypeAdapter<RecurringTransaction> {
  @override
  final int typeId = 5;

  @override
  RecurringTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransaction(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      amountInCents: fields[3] as int,
      isIncome: fields[4] as bool,
      category: fields[5] as String,
      recurrenceType: fields[6] as RecurrenceType,
      startDate: fields[7] as DateTime,
      nextOccurrence: fields[8] as DateTime,
      endDate: fields[9] as DateTime?,
      status: fields[10] as RecurringTransactionStatus,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      userId: fields[13] as String,
      reminderEnabled: fields[14] as bool,
      reminderDaysBefore: fields[15] as int,
      merchantName: fields[16] as String,
      iconName: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransaction obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amountInCents)
      ..writeByte(4)
      ..write(obj.isIncome)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.recurrenceType)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.nextOccurrence)
      ..writeByte(9)
      ..write(obj.endDate)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.userId)
      ..writeByte(14)
      ..write(obj.reminderEnabled)
      ..writeByte(15)
      ..write(obj.reminderDaysBefore)
      ..writeByte(16)
      ..write(obj.merchantName)
      ..writeByte(17)
      ..write(obj.iconName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceTypeAdapter extends TypeAdapter<RecurrenceType> {
  @override
  final int typeId = 7;

  @override
  RecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceType.weekly;
      case 1:
        return RecurrenceType.monthly;
      case 2:
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceType obj) {
    switch (obj) {
      case RecurrenceType.weekly:
        writer.writeByte(0);
        break;
      case RecurrenceType.monthly:
        writer.writeByte(1);
        break;
      case RecurrenceType.yearly:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringTransactionStatusAdapter
    extends TypeAdapter<RecurringTransactionStatus> {
  @override
  final int typeId = 8;

  @override
  RecurringTransactionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringTransactionStatus.active;
      case 1:
        return RecurringTransactionStatus.paused;
      case 2:
        return RecurringTransactionStatus.cancelled;
      default:
        return RecurringTransactionStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringTransactionStatus obj) {
    switch (obj) {
      case RecurringTransactionStatus.active:
        writer.writeByte(0);
        break;
      case RecurringTransactionStatus.paused:
        writer.writeByte(1);
        break;
      case RecurringTransactionStatus.cancelled:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
