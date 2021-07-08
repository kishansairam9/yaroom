// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final int msgId;
  final int fromUser;
  final int toUser;
  final DateTime time;
  final String? content;
  final String? media;
  final int? replyTo;
  ChatMessage(
      {required this.msgId,
      required this.fromUser,
      required this.toUser,
      required this.time,
      this.content,
      this.media,
      this.replyTo});
  factory ChatMessage.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return ChatMessage(
      msgId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}msgId'])!,
      fromUser: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}fromUser'])!,
      toUser: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}toUser'])!,
      time: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}time'])!,
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content']),
      media: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}media']),
      replyTo: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}replyTo']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['msgId'] = Variable<int>(msgId);
    map['fromUser'] = Variable<int>(fromUser);
    map['toUser'] = Variable<int>(toUser);
    map['time'] = Variable<DateTime>(time);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String?>(content);
    }
    if (!nullToAbsent || media != null) {
      map['media'] = Variable<String?>(media);
    }
    if (!nullToAbsent || replyTo != null) {
      map['replyTo'] = Variable<int?>(replyTo);
    }
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      msgId: Value(msgId),
      fromUser: Value(fromUser),
      toUser: Value(toUser),
      time: Value(time),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      media:
          media == null && nullToAbsent ? const Value.absent() : Value(media),
      replyTo: replyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(replyTo),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return ChatMessage(
      msgId: serializer.fromJson<int>(json['msgId']),
      fromUser: serializer.fromJson<int>(json['fromUser']),
      toUser: serializer.fromJson<int>(json['toUser']),
      time: serializer.fromJson<DateTime>(json['time']),
      content: serializer.fromJson<String?>(json['content']),
      media: serializer.fromJson<String?>(json['media']),
      replyTo: serializer.fromJson<int?>(json['replyTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'msgId': serializer.toJson<int>(msgId),
      'fromUser': serializer.toJson<int>(fromUser),
      'toUser': serializer.toJson<int>(toUser),
      'time': serializer.toJson<DateTime>(time),
      'content': serializer.toJson<String?>(content),
      'media': serializer.toJson<String?>(media),
      'replyTo': serializer.toJson<int?>(replyTo),
    };
  }

  ChatMessage copyWith(
          {int? msgId,
          int? fromUser,
          int? toUser,
          DateTime? time,
          Value<String?> content = const Value.absent(),
          Value<String?> media = const Value.absent(),
          Value<int?> replyTo = const Value.absent()}) =>
      ChatMessage(
        msgId: msgId ?? this.msgId,
        fromUser: fromUser ?? this.fromUser,
        toUser: toUser ?? this.toUser,
        time: time ?? this.time,
        content: content.present ? content.value : this.content,
        media: media.present ? media.value : this.media,
        replyTo: replyTo.present ? replyTo.value : this.replyTo,
      );
  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('msgId: $msgId, ')
          ..write('fromUser: $fromUser, ')
          ..write('toUser: $toUser, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('media: $media, ')
          ..write('replyTo: $replyTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      msgId.hashCode,
      $mrjc(
          fromUser.hashCode,
          $mrjc(
              toUser.hashCode,
              $mrjc(
                  time.hashCode,
                  $mrjc(content.hashCode,
                      $mrjc(media.hashCode, replyTo.hashCode)))))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.msgId == this.msgId &&
          other.fromUser == this.fromUser &&
          other.toUser == this.toUser &&
          other.time == this.time &&
          other.content == this.content &&
          other.media == this.media &&
          other.replyTo == this.replyTo);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<int> msgId;
  final Value<int> fromUser;
  final Value<int> toUser;
  final Value<DateTime> time;
  final Value<String?> content;
  final Value<String?> media;
  final Value<int?> replyTo;
  const ChatMessagesCompanion({
    this.msgId = const Value.absent(),
    this.fromUser = const Value.absent(),
    this.toUser = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.media = const Value.absent(),
    this.replyTo = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    this.msgId = const Value.absent(),
    required int fromUser,
    required int toUser,
    required DateTime time,
    this.content = const Value.absent(),
    this.media = const Value.absent(),
    this.replyTo = const Value.absent(),
  })  : fromUser = Value(fromUser),
        toUser = Value(toUser),
        time = Value(time);
  static Insertable<ChatMessage> custom({
    Expression<int>? msgId,
    Expression<int>? fromUser,
    Expression<int>? toUser,
    Expression<DateTime>? time,
    Expression<String?>? content,
    Expression<String?>? media,
    Expression<int?>? replyTo,
  }) {
    return RawValuesInsertable({
      if (msgId != null) 'msgId': msgId,
      if (fromUser != null) 'fromUser': fromUser,
      if (toUser != null) 'toUser': toUser,
      if (time != null) 'time': time,
      if (content != null) 'content': content,
      if (media != null) 'media': media,
      if (replyTo != null) 'replyTo': replyTo,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<int>? msgId,
      Value<int>? fromUser,
      Value<int>? toUser,
      Value<DateTime>? time,
      Value<String?>? content,
      Value<String?>? media,
      Value<int?>? replyTo}) {
    return ChatMessagesCompanion(
      msgId: msgId ?? this.msgId,
      fromUser: fromUser ?? this.fromUser,
      toUser: toUser ?? this.toUser,
      time: time ?? this.time,
      content: content ?? this.content,
      media: media ?? this.media,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (msgId.present) {
      map['msgId'] = Variable<int>(msgId.value);
    }
    if (fromUser.present) {
      map['fromUser'] = Variable<int>(fromUser.value);
    }
    if (toUser.present) {
      map['toUser'] = Variable<int>(toUser.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (content.present) {
      map['content'] = Variable<String?>(content.value);
    }
    if (media.present) {
      map['media'] = Variable<String?>(media.value);
    }
    if (replyTo.present) {
      map['replyTo'] = Variable<int?>(replyTo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('msgId: $msgId, ')
          ..write('fromUser: $fromUser, ')
          ..write('toUser: $toUser, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('media: $media, ')
          ..write('replyTo: $replyTo')
          ..write(')'))
        .toString();
  }
}

class ChatMessages extends Table with TableInfo<ChatMessages, ChatMessage> {
  final GeneratedDatabase _db;
  final String? _alias;
  ChatMessages(this._db, [this._alias]);
  final VerificationMeta _msgIdMeta = const VerificationMeta('msgId');
  late final GeneratedColumn<int?> msgId = GeneratedColumn<int?>(
      'msgId', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  final VerificationMeta _fromUserMeta = const VerificationMeta('fromUser');
  late final GeneratedColumn<int?> fromUser = GeneratedColumn<int?>(
      'fromUser', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  final VerificationMeta _toUserMeta = const VerificationMeta('toUser');
  late final GeneratedColumn<int?> toUser = GeneratedColumn<int?>(
      'toUser', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  final VerificationMeta _timeMeta = const VerificationMeta('time');
  late final GeneratedColumn<DateTime?> time = GeneratedColumn<DateTime?>(
      'time', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedColumn<String?> content = GeneratedColumn<String?>(
      'content', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false, $customConstraints: '');
  final VerificationMeta _mediaMeta = const VerificationMeta('media');
  late final GeneratedColumn<String?> media = GeneratedColumn<String?>(
      'media', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false, $customConstraints: '');
  final VerificationMeta _replyToMeta = const VerificationMeta('replyTo');
  late final GeneratedColumn<int?> replyTo = GeneratedColumn<int?>(
      'replyTo', aliasedName, true,
      typeName: 'INTEGER', requiredDuringInsert: false, $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [msgId, fromUser, toUser, time, content, media, replyTo];
  @override
  String get aliasedName => _alias ?? 'ChatMessages';
  @override
  String get actualTableName => 'ChatMessages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('msgId')) {
      context.handle(
          _msgIdMeta, msgId.isAcceptableOrUnknown(data['msgId']!, _msgIdMeta));
    }
    if (data.containsKey('fromUser')) {
      context.handle(_fromUserMeta,
          fromUser.isAcceptableOrUnknown(data['fromUser']!, _fromUserMeta));
    } else if (isInserting) {
      context.missing(_fromUserMeta);
    }
    if (data.containsKey('toUser')) {
      context.handle(_toUserMeta,
          toUser.isAcceptableOrUnknown(data['toUser']!, _toUserMeta));
    } else if (isInserting) {
      context.missing(_toUserMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('media')) {
      context.handle(
          _mediaMeta, media.isAcceptableOrUnknown(data['media']!, _mediaMeta));
    }
    if (data.containsKey('replyTo')) {
      context.handle(_replyToMeta,
          replyTo.isAcceptableOrUnknown(data['replyTo']!, _replyToMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {msgId};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    return ChatMessage.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  ChatMessages createAlias(String alias) {
    return ChatMessages(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ChatMessagesTextIndexData extends DataClass
    implements Insertable<ChatMessagesTextIndexData> {
  final String fromUser;
  final String toUser;
  final String time;
  final String content;
  final String media;
  final String replyTo;
  ChatMessagesTextIndexData(
      {required this.fromUser,
      required this.toUser,
      required this.time,
      required this.content,
      required this.media,
      required this.replyTo});
  factory ChatMessagesTextIndexData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return ChatMessagesTextIndexData(
      fromUser: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}fromUser'])!,
      toUser: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}toUser'])!,
      time: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}time'])!,
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content'])!,
      media: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}media'])!,
      replyTo: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}replyTo'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fromUser'] = Variable<String>(fromUser);
    map['toUser'] = Variable<String>(toUser);
    map['time'] = Variable<String>(time);
    map['content'] = Variable<String>(content);
    map['media'] = Variable<String>(media);
    map['replyTo'] = Variable<String>(replyTo);
    return map;
  }

  ChatMessagesTextIndexCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesTextIndexCompanion(
      fromUser: Value(fromUser),
      toUser: Value(toUser),
      time: Value(time),
      content: Value(content),
      media: Value(media),
      replyTo: Value(replyTo),
    );
  }

  factory ChatMessagesTextIndexData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return ChatMessagesTextIndexData(
      fromUser: serializer.fromJson<String>(json['fromUser']),
      toUser: serializer.fromJson<String>(json['toUser']),
      time: serializer.fromJson<String>(json['time']),
      content: serializer.fromJson<String>(json['content']),
      media: serializer.fromJson<String>(json['media']),
      replyTo: serializer.fromJson<String>(json['replyTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromUser': serializer.toJson<String>(fromUser),
      'toUser': serializer.toJson<String>(toUser),
      'time': serializer.toJson<String>(time),
      'content': serializer.toJson<String>(content),
      'media': serializer.toJson<String>(media),
      'replyTo': serializer.toJson<String>(replyTo),
    };
  }

  ChatMessagesTextIndexData copyWith(
          {String? fromUser,
          String? toUser,
          String? time,
          String? content,
          String? media,
          String? replyTo}) =>
      ChatMessagesTextIndexData(
        fromUser: fromUser ?? this.fromUser,
        toUser: toUser ?? this.toUser,
        time: time ?? this.time,
        content: content ?? this.content,
        media: media ?? this.media,
        replyTo: replyTo ?? this.replyTo,
      );
  @override
  String toString() {
    return (StringBuffer('ChatMessagesTextIndexData(')
          ..write('fromUser: $fromUser, ')
          ..write('toUser: $toUser, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('media: $media, ')
          ..write('replyTo: $replyTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      fromUser.hashCode,
      $mrjc(
          toUser.hashCode,
          $mrjc(
              time.hashCode,
              $mrjc(content.hashCode,
                  $mrjc(media.hashCode, replyTo.hashCode))))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessagesTextIndexData &&
          other.fromUser == this.fromUser &&
          other.toUser == this.toUser &&
          other.time == this.time &&
          other.content == this.content &&
          other.media == this.media &&
          other.replyTo == this.replyTo);
}

class ChatMessagesTextIndexCompanion
    extends UpdateCompanion<ChatMessagesTextIndexData> {
  final Value<String> fromUser;
  final Value<String> toUser;
  final Value<String> time;
  final Value<String> content;
  final Value<String> media;
  final Value<String> replyTo;
  const ChatMessagesTextIndexCompanion({
    this.fromUser = const Value.absent(),
    this.toUser = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.media = const Value.absent(),
    this.replyTo = const Value.absent(),
  });
  ChatMessagesTextIndexCompanion.insert({
    required String fromUser,
    required String toUser,
    required String time,
    required String content,
    required String media,
    required String replyTo,
  })  : fromUser = Value(fromUser),
        toUser = Value(toUser),
        time = Value(time),
        content = Value(content),
        media = Value(media),
        replyTo = Value(replyTo);
  static Insertable<ChatMessagesTextIndexData> custom({
    Expression<String>? fromUser,
    Expression<String>? toUser,
    Expression<String>? time,
    Expression<String>? content,
    Expression<String>? media,
    Expression<String>? replyTo,
  }) {
    return RawValuesInsertable({
      if (fromUser != null) 'fromUser': fromUser,
      if (toUser != null) 'toUser': toUser,
      if (time != null) 'time': time,
      if (content != null) 'content': content,
      if (media != null) 'media': media,
      if (replyTo != null) 'replyTo': replyTo,
    });
  }

  ChatMessagesTextIndexCompanion copyWith(
      {Value<String>? fromUser,
      Value<String>? toUser,
      Value<String>? time,
      Value<String>? content,
      Value<String>? media,
      Value<String>? replyTo}) {
    return ChatMessagesTextIndexCompanion(
      fromUser: fromUser ?? this.fromUser,
      toUser: toUser ?? this.toUser,
      time: time ?? this.time,
      content: content ?? this.content,
      media: media ?? this.media,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromUser.present) {
      map['fromUser'] = Variable<String>(fromUser.value);
    }
    if (toUser.present) {
      map['toUser'] = Variable<String>(toUser.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (media.present) {
      map['media'] = Variable<String>(media.value);
    }
    if (replyTo.present) {
      map['replyTo'] = Variable<String>(replyTo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesTextIndexCompanion(')
          ..write('fromUser: $fromUser, ')
          ..write('toUser: $toUser, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('media: $media, ')
          ..write('replyTo: $replyTo')
          ..write(')'))
        .toString();
  }
}

class ChatMessagesTextIndex extends Table
    with
        TableInfo<ChatMessagesTextIndex, ChatMessagesTextIndexData>,
        VirtualTableInfo<ChatMessagesTextIndex, ChatMessagesTextIndexData> {
  final GeneratedDatabase _db;
  final String? _alias;
  ChatMessagesTextIndex(this._db, [this._alias]);
  final VerificationMeta _fromUserMeta = const VerificationMeta('fromUser');
  late final GeneratedColumn<String?> fromUser = GeneratedColumn<String?>(
      'fromUser', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
  final VerificationMeta _toUserMeta = const VerificationMeta('toUser');
  late final GeneratedColumn<String?> toUser = GeneratedColumn<String?>(
      'toUser', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
  final VerificationMeta _timeMeta = const VerificationMeta('time');
  late final GeneratedColumn<String?> time = GeneratedColumn<String?>(
      'time', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedColumn<String?> content = GeneratedColumn<String?>(
      'content', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
  final VerificationMeta _mediaMeta = const VerificationMeta('media');
  late final GeneratedColumn<String?> media = GeneratedColumn<String?>(
      'media', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
  final VerificationMeta _replyToMeta = const VerificationMeta('replyTo');
  late final GeneratedColumn<String?> replyTo = GeneratedColumn<String?>(
      'replyTo', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [fromUser, toUser, time, content, media, replyTo];
  @override
  String get aliasedName => _alias ?? 'ChatMessagesTextIndex';
  @override
  String get actualTableName => 'ChatMessagesTextIndex';
  @override
  VerificationContext validateIntegrity(
      Insertable<ChatMessagesTextIndexData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fromUser')) {
      context.handle(_fromUserMeta,
          fromUser.isAcceptableOrUnknown(data['fromUser']!, _fromUserMeta));
    } else if (isInserting) {
      context.missing(_fromUserMeta);
    }
    if (data.containsKey('toUser')) {
      context.handle(_toUserMeta,
          toUser.isAcceptableOrUnknown(data['toUser']!, _toUserMeta));
    } else if (isInserting) {
      context.missing(_toUserMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('media')) {
      context.handle(
          _mediaMeta, media.isAcceptableOrUnknown(data['media']!, _mediaMeta));
    } else if (isInserting) {
      context.missing(_mediaMeta);
    }
    if (data.containsKey('replyTo')) {
      context.handle(_replyToMeta,
          replyTo.isAcceptableOrUnknown(data['replyTo']!, _replyToMeta));
    } else if (isInserting) {
      context.missing(_replyToMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  ChatMessagesTextIndexData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    return ChatMessagesTextIndexData.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  ChatMessagesTextIndex createAlias(String alias) {
    return ChatMessagesTextIndex(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(fromUser UNINDEXED, toUser UNINDEXED, time UNINDEXED, content, media UNINDEXED, replyTo UNINDEXED, content=\'ChatMessages\', content_rowid=\'msgId\', tokenize = \'porter unicode61\')';
}

class User extends DataClass implements Insertable<User> {
  final int userId;
  final String name;
  final String? about;
  final String? profileImg;
  User({required this.userId, required this.name, this.about, this.profileImg});
  factory User.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return User(
      userId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}userId'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      about: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}about']),
      profileImg: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}profileImg']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['userId'] = Variable<int>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || about != null) {
      map['about'] = Variable<String?>(about);
    }
    if (!nullToAbsent || profileImg != null) {
      map['profileImg'] = Variable<String?>(profileImg);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      userId: Value(userId),
      name: Value(name),
      about:
          about == null && nullToAbsent ? const Value.absent() : Value(about),
      profileImg: profileImg == null && nullToAbsent
          ? const Value.absent()
          : Value(profileImg),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return User(
      userId: serializer.fromJson<int>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      about: serializer.fromJson<String?>(json['about']),
      profileImg: serializer.fromJson<String?>(json['profileImg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'name': serializer.toJson<String>(name),
      'about': serializer.toJson<String?>(about),
      'profileImg': serializer.toJson<String?>(profileImg),
    };
  }

  User copyWith(
          {int? userId,
          String? name,
          Value<String?> about = const Value.absent(),
          Value<String?> profileImg = const Value.absent()}) =>
      User(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        about: about.present ? about.value : this.about,
        profileImg: profileImg.present ? profileImg.value : this.profileImg,
      );
  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('about: $about, ')
          ..write('profileImg: $profileImg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(userId.hashCode,
      $mrjc(name.hashCode, $mrjc(about.hashCode, profileImg.hashCode))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.about == this.about &&
          other.profileImg == this.profileImg);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> userId;
  final Value<String> name;
  final Value<String?> about;
  final Value<String?> profileImg;
  const UsersCompanion({
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.about = const Value.absent(),
    this.profileImg = const Value.absent(),
  });
  UsersCompanion.insert({
    this.userId = const Value.absent(),
    required String name,
    this.about = const Value.absent(),
    this.profileImg = const Value.absent(),
  }) : name = Value(name);
  static Insertable<User> custom({
    Expression<int>? userId,
    Expression<String>? name,
    Expression<String?>? about,
    Expression<String?>? profileImg,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'userId': userId,
      if (name != null) 'name': name,
      if (about != null) 'about': about,
      if (profileImg != null) 'profileImg': profileImg,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? userId,
      Value<String>? name,
      Value<String?>? about,
      Value<String?>? profileImg}) {
    return UsersCompanion(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      about: about ?? this.about,
      profileImg: profileImg ?? this.profileImg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['userId'] = Variable<int>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (about.present) {
      map['about'] = Variable<String?>(about.value);
    }
    if (profileImg.present) {
      map['profileImg'] = Variable<String?>(profileImg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('about: $about, ')
          ..write('profileImg: $profileImg')
          ..write(')'))
        .toString();
  }
}

class Users extends Table with TableInfo<Users, User> {
  final GeneratedDatabase _db;
  final String? _alias;
  Users(this._db, [this._alias]);
  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<int?> userId = GeneratedColumn<int?>(
      'userId', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  final VerificationMeta _aboutMeta = const VerificationMeta('about');
  late final GeneratedColumn<String?> about = GeneratedColumn<String?>(
      'about', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false, $customConstraints: '');
  final VerificationMeta _profileImgMeta = const VerificationMeta('profileImg');
  late final GeneratedColumn<String?> profileImg = GeneratedColumn<String?>(
      'profileImg', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false, $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [userId, name, about, profileImg];
  @override
  String get aliasedName => _alias ?? 'Users';
  @override
  String get actualTableName => 'Users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('userId')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['userId']!, _userIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('about')) {
      context.handle(
          _aboutMeta, about.isAcceptableOrUnknown(data['about']!, _aboutMeta));
    }
    if (data.containsKey('profileImg')) {
      context.handle(
          _profileImgMeta,
          profileImg.isAcceptableOrUnknown(
              data['profileImg']!, _profileImgMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    return User.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  Users createAlias(String alias) {
    return Users(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final ChatMessages chatMessages = ChatMessages(this);
  late final Index fromUserIndex = Index(
      'fromUserIndex', 'CREATE INDEX fromUserIndex ON ChatMessages (fromUser)');
  late final Index toUserIndex =
      Index('toUserIndex', 'CREATE INDEX toUserIndex ON ChatMessages (toUser)');
  late final ChatMessagesTextIndex chatMessagesTextIndex =
      ChatMessagesTextIndex(this);
  late final Trigger chatMessagesTextIndexAI = Trigger(
      'CREATE TRIGGER ChatMessagesTextIndex_AI AFTER INSERT ON ChatMessages BEGIN INSERT INTO ChatMessagesTextIndex ("rowid", fromUser, toUser, time, content, media, replyTo) VALUES (new.msgId, new.fromUser, new.toUser, new.time, new.content, new.media, new.replyTo);END',
      'ChatMessagesTextIndex_AI');
  late final Trigger chatMessagesTextIndexAD = Trigger(
      'CREATE TRIGGER ChatMessagesTextIndex_AD AFTER DELETE ON ChatMessages BEGIN INSERT INTO ChatMessagesTextIndex (ChatMessagesTextIndex, "rowid", fromUser, toUser, time, content, media, replyTo) VALUES (\'delete\', old.msgId, old.fromUser, old.toUser, old.time, old.content, old.media, old.replyTo);END',
      'ChatMessagesTextIndex_AD');
  late final Trigger chatMessagesTextIndexAU = Trigger(
      'CREATE TRIGGER ChatMessagesTextIndex_AU AFTER UPDATE ON ChatMessages BEGIN INSERT INTO ChatMessagesTextIndex (ChatMessagesTextIndex, "rowid", fromUser, toUser, time, content, media, replyTo) VALUES (\'delete\', old.msgId, old.fromUser, old.toUser, old.time, old.content, old.media, old.replyTo);INSERT INTO ChatMessagesTextIndex ("rowid", fromUser, toUser, time, content, media, replyTo) VALUES (new.msgId, new.fromUser, new.toUser, new.time, new.content, new.media, new.replyTo);END',
      'ChatMessagesTextIndex_AU');
  late final Users users = Users(this);
  Future<int> addUser(
      {required int userId,
      required String name,
      String? about,
      String? profileImg}) {
    return customInsert(
      'INSERT INTO Users VALUES (:userId, :name, :about, :profileImg)',
      variables: [
        Variable<int>(userId),
        Variable<String>(name),
        Variable<String?>(about),
        Variable<String?>(profileImg)
      ],
      updates: {users},
    );
  }

  Selectable<User> getAllUsers() {
    return customSelect('SELECT * FROM Users', variables: [], readsFrom: {
      users,
    }).map(users.mapFromRow);
  }

  Selectable<ChatMessage> getUserChat({required int otherUser}) {
    return customSelect(
        'SELECT * FROM ChatMessages WHERE fromUser = :otherUser OR toUser = :otherUser',
        variables: [
          Variable<int>(otherUser)
        ],
        readsFrom: {
          chatMessages,
        }).map(chatMessages.mapFromRow);
  }

  Future<int> insertTextMessage(
      {required int msgId,
      required int fromUser,
      required int toUser,
      required DateTime time,
      required String content,
      int? replyTo}) {
    return customInsert(
      'INSERT INTO ChatMessages VALUES (:msgId, :fromUser, :toUser, :time, :content, NULL, :replyTo)',
      variables: [
        Variable<int>(msgId),
        Variable<int>(fromUser),
        Variable<int>(toUser),
        Variable<DateTime>(time),
        Variable<String>(content),
        Variable<int?>(replyTo)
      ],
      updates: {chatMessages},
    );
  }

  Future<int> insertMediaMessage(
      {required int msgId,
      required int fromUser,
      required int toUser,
      required DateTime time,
      String? content,
      required String media,
      int? replyTo}) {
    return customInsert(
      'INSERT INTO ChatMessages VALUES (:msgId, :fromUser, :toUser, :time, :content, :media, :replyTo)',
      variables: [
        Variable<int>(msgId),
        Variable<int>(fromUser),
        Variable<int>(toUser),
        Variable<DateTime>(time),
        Variable<String?>(content),
        Variable<String>(media),
        Variable<int?>(replyTo)
      ],
      updates: {chatMessages},
    );
  }

  Selectable<SearchChatMessagesResult> searchChatMessages(
      {required String query, int? limit}) {
    return customSelect(
        'SELECT c.content, u.* FROM Users AS u JOIN (SELECT fromUser, toUser, content FROM ChatMessagesTextIndex WHERE content MATCH :query ORDER BY rank LIMIT :limit) AS c ON c.fromUser = u.userId OR c.toUser = u.userId',
        variables: [
          Variable<String>(query),
          Variable<int?>(limit)
        ],
        readsFrom: {
          users,
          chatMessagesTextIndex,
        }).map((QueryRow row) {
      return SearchChatMessagesResult(
        content: row.read<String>('content'),
        userId: row.read<int>('userId'),
        name: row.read<String>('name'),
        about: row.read<String?>('about'),
        profileImg: row.read<String?>('profileImg'),
      );
    });
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        chatMessages,
        fromUserIndex,
        toUserIndex,
        chatMessagesTextIndex,
        chatMessagesTextIndexAI,
        chatMessagesTextIndexAD,
        chatMessagesTextIndexAU,
        users
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('ChatMessages',
                limitUpdateKind: UpdateKind.insert),
            result: [
              TableUpdate('ChatMessagesTextIndex', kind: UpdateKind.insert),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('ChatMessages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('ChatMessagesTextIndex', kind: UpdateKind.insert),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('ChatMessages',
                limitUpdateKind: UpdateKind.update),
            result: [
              TableUpdate('ChatMessagesTextIndex', kind: UpdateKind.insert),
            ],
          ),
        ],
      );
}

class SearchChatMessagesResult {
  final String content;
  final int userId;
  final String name;
  final String? about;
  final String? profileImg;
  SearchChatMessagesResult({
    required this.content,
    required this.userId,
    required this.name,
    this.about,
    this.profileImg,
  });
}
