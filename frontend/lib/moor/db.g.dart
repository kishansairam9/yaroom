// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class User extends DataClass implements Insertable<User> {
  final String userId;
  final String name;
  final String? about;
  final String? profileImg;
  User({required this.userId, required this.name, this.about, this.profileImg});
  factory User.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return User(
      userId: const StringType()
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
    map['userId'] = Variable<String>(userId);
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
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      about: serializer.fromJson<String?>(json['about']),
      profileImg: serializer.fromJson<String?>(json['profileImg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'about': serializer.toJson<String?>(about),
      'profileImg': serializer.toJson<String?>(profileImg),
    };
  }

  User copyWith(
          {String? userId,
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
  final Value<String> userId;
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
    required String userId,
    required String name,
    this.about = const Value.absent(),
    this.profileImg = const Value.absent(),
  })  : userId = Value(userId),
        name = Value(name);
  static Insertable<User> custom({
    Expression<String>? userId,
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
      {Value<String>? userId,
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
      map['userId'] = Variable<String>(userId.value);
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
  late final GeneratedColumn<String?> userId = GeneratedColumn<String?>(
      'userId', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
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

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final String msgId;
  final String fromUser;
  final String toUser;
  final DateTime time;
  final String? content;
  final String? media;
  final String? replyTo;
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
      msgId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}msgId'])!,
      fromUser: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}fromUser'])!,
      toUser: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}toUser'])!,
      time: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}time'])!,
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content']),
      media: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}media']),
      replyTo: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}replyTo']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['msgId'] = Variable<String>(msgId);
    map['fromUser'] = Variable<String>(fromUser);
    map['toUser'] = Variable<String>(toUser);
    map['time'] = Variable<DateTime>(time);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String?>(content);
    }
    if (!nullToAbsent || media != null) {
      map['media'] = Variable<String?>(media);
    }
    if (!nullToAbsent || replyTo != null) {
      map['replyTo'] = Variable<String?>(replyTo);
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
      msgId: serializer.fromJson<String>(json['msgId']),
      fromUser: serializer.fromJson<String>(json['fromUser']),
      toUser: serializer.fromJson<String>(json['toUser']),
      time: serializer.fromJson<DateTime>(json['time']),
      content: serializer.fromJson<String?>(json['content']),
      media: serializer.fromJson<String?>(json['media']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'msgId': serializer.toJson<String>(msgId),
      'fromUser': serializer.toJson<String>(fromUser),
      'toUser': serializer.toJson<String>(toUser),
      'time': serializer.toJson<DateTime>(time),
      'content': serializer.toJson<String?>(content),
      'media': serializer.toJson<String?>(media),
      'replyTo': serializer.toJson<String?>(replyTo),
    };
  }

  ChatMessage copyWith(
          {String? msgId,
          String? fromUser,
          String? toUser,
          DateTime? time,
          Value<String?> content = const Value.absent(),
          Value<String?> media = const Value.absent(),
          Value<String?> replyTo = const Value.absent()}) =>
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
  final Value<String> msgId;
  final Value<String> fromUser;
  final Value<String> toUser;
  final Value<DateTime> time;
  final Value<String?> content;
  final Value<String?> media;
  final Value<String?> replyTo;
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
    required String msgId,
    required String fromUser,
    required String toUser,
    required DateTime time,
    this.content = const Value.absent(),
    this.media = const Value.absent(),
    this.replyTo = const Value.absent(),
  })  : msgId = Value(msgId),
        fromUser = Value(fromUser),
        toUser = Value(toUser),
        time = Value(time);
  static Insertable<ChatMessage> custom({
    Expression<String>? msgId,
    Expression<String>? fromUser,
    Expression<String>? toUser,
    Expression<DateTime>? time,
    Expression<String?>? content,
    Expression<String?>? media,
    Expression<String?>? replyTo,
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
      {Value<String>? msgId,
      Value<String>? fromUser,
      Value<String>? toUser,
      Value<DateTime>? time,
      Value<String?>? content,
      Value<String?>? media,
      Value<String?>? replyTo}) {
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
      map['msgId'] = Variable<String>(msgId.value);
    }
    if (fromUser.present) {
      map['fromUser'] = Variable<String>(fromUser.value);
    }
    if (toUser.present) {
      map['toUser'] = Variable<String>(toUser.value);
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
      map['replyTo'] = Variable<String?>(replyTo.value);
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
  late final GeneratedColumn<String?> msgId = GeneratedColumn<String?>(
      'msgId', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  final VerificationMeta _fromUserMeta = const VerificationMeta('fromUser');
  late final GeneratedColumn<String?> fromUser = GeneratedColumn<String?>(
      'fromUser', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES Users(userId)');
  final VerificationMeta _toUserMeta = const VerificationMeta('toUser');
  late final GeneratedColumn<String?> toUser = GeneratedColumn<String?>(
      'toUser', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES Users(userId)');
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
  late final GeneratedColumn<String?> replyTo = GeneratedColumn<String?>(
      'replyTo', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false, $customConstraints: '');
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
    } else if (isInserting) {
      context.missing(_msgIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
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
  List<String> get customConstraints => const [
        'CONSTRAINT hasData CHECK (content IS NOT NULL OR media IS NOT NULL)'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class GroupDM extends DataClass implements Insertable<GroupDM> {
  final String groupId;
  final String name;
  final String? description;
  final String? groupIcon;
  GroupDM(
      {required this.groupId,
      required this.name,
      this.description,
      this.groupIcon});
  factory GroupDM.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return GroupDM(
      groupId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}groupId'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      description: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}description']),
      groupIcon: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}groupIcon']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['groupId'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String?>(description);
    }
    if (!nullToAbsent || groupIcon != null) {
      map['groupIcon'] = Variable<String?>(groupIcon);
    }
    return map;
  }

  GroupDMsCompanion toCompanion(bool nullToAbsent) {
    return GroupDMsCompanion(
      groupId: Value(groupId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      groupIcon: groupIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(groupIcon),
    );
  }

  factory GroupDM.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return GroupDM(
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      groupIcon: serializer.fromJson<String?>(json['groupIcon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'groupIcon': serializer.toJson<String?>(groupIcon),
    };
  }

  GroupDM copyWith(
          {String? groupId,
          String? name,
          Value<String?> description = const Value.absent(),
          Value<String?> groupIcon = const Value.absent()}) =>
      GroupDM(
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        groupIcon: groupIcon.present ? groupIcon.value : this.groupIcon,
      );
  @override
  String toString() {
    return (StringBuffer('GroupDM(')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('groupIcon: $groupIcon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(groupId.hashCode,
      $mrjc(name.hashCode, $mrjc(description.hashCode, groupIcon.hashCode))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupDM &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.description == this.description &&
          other.groupIcon == this.groupIcon);
}

class GroupDMsCompanion extends UpdateCompanion<GroupDM> {
  final Value<String> groupId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> groupIcon;
  const GroupDMsCompanion({
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.groupIcon = const Value.absent(),
  });
  GroupDMsCompanion.insert({
    required String groupId,
    required String name,
    this.description = const Value.absent(),
    this.groupIcon = const Value.absent(),
  })  : groupId = Value(groupId),
        name = Value(name);
  static Insertable<GroupDM> custom({
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<String?>? description,
    Expression<String?>? groupIcon,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'groupId': groupId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (groupIcon != null) 'groupIcon': groupIcon,
    });
  }

  GroupDMsCompanion copyWith(
      {Value<String>? groupId,
      Value<String>? name,
      Value<String?>? description,
      Value<String?>? groupIcon}) {
    return GroupDMsCompanion(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      groupIcon: groupIcon ?? this.groupIcon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['groupId'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String?>(description.value);
    }
    if (groupIcon.present) {
      map['groupIcon'] = Variable<String?>(groupIcon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupDMsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('groupIcon: $groupIcon')
          ..write(')'))
        .toString();
  }
}

class GroupDMs extends Table with TableInfo<GroupDMs, GroupDM> {
  final GeneratedDatabase _db;
  final String? _alias;
  GroupDMs(this._db, [this._alias]);
  final VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  late final GeneratedColumn<String?> groupId = GeneratedColumn<String?>(
      'groupId', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  late final GeneratedColumn<String?> description = GeneratedColumn<String?>(
      'description', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false, $customConstraints: '');
  final VerificationMeta _groupIconMeta = const VerificationMeta('groupIcon');
  late final GeneratedColumn<String?> groupIcon = GeneratedColumn<String?>(
      'groupIcon', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false, $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [groupId, name, description, groupIcon];
  @override
  String get aliasedName => _alias ?? 'GroupDMs';
  @override
  String get actualTableName => 'GroupDMs';
  @override
  VerificationContext validateIntegrity(Insertable<GroupDM> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('groupId')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['groupId']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('groupIcon')) {
      context.handle(_groupIconMeta,
          groupIcon.isAcceptableOrUnknown(data['groupIcon']!, _groupIconMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  GroupDM map(Map<String, dynamic> data, {String? tablePrefix}) {
    return GroupDM.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  GroupDMs createAlias(String alias) {
    return GroupDMs(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class GroupChatMessage extends DataClass
    implements Insertable<GroupChatMessage> {
  final String msgId;
  final String groupId;
  final String fromUser;
  final DateTime time;
  final String? content;
  final String? media;
  final String? replyTo;
  GroupChatMessage(
      {required this.msgId,
      required this.groupId,
      required this.fromUser,
      required this.time,
      this.content,
      this.media,
      this.replyTo});
  factory GroupChatMessage.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return GroupChatMessage(
      msgId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}msgId'])!,
      groupId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}groupId'])!,
      fromUser: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}fromUser'])!,
      time: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}time'])!,
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content']),
      media: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}media']),
      replyTo: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}replyTo']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['msgId'] = Variable<String>(msgId);
    map['groupId'] = Variable<String>(groupId);
    map['fromUser'] = Variable<String>(fromUser);
    map['time'] = Variable<DateTime>(time);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String?>(content);
    }
    if (!nullToAbsent || media != null) {
      map['media'] = Variable<String?>(media);
    }
    if (!nullToAbsent || replyTo != null) {
      map['replyTo'] = Variable<String?>(replyTo);
    }
    return map;
  }

  GroupChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return GroupChatMessagesCompanion(
      msgId: Value(msgId),
      groupId: Value(groupId),
      fromUser: Value(fromUser),
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

  factory GroupChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return GroupChatMessage(
      msgId: serializer.fromJson<String>(json['msgId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      fromUser: serializer.fromJson<String>(json['fromUser']),
      time: serializer.fromJson<DateTime>(json['time']),
      content: serializer.fromJson<String?>(json['content']),
      media: serializer.fromJson<String?>(json['media']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'msgId': serializer.toJson<String>(msgId),
      'groupId': serializer.toJson<String>(groupId),
      'fromUser': serializer.toJson<String>(fromUser),
      'time': serializer.toJson<DateTime>(time),
      'content': serializer.toJson<String?>(content),
      'media': serializer.toJson<String?>(media),
      'replyTo': serializer.toJson<String?>(replyTo),
    };
  }

  GroupChatMessage copyWith(
          {String? msgId,
          String? groupId,
          String? fromUser,
          DateTime? time,
          Value<String?> content = const Value.absent(),
          Value<String?> media = const Value.absent(),
          Value<String?> replyTo = const Value.absent()}) =>
      GroupChatMessage(
        msgId: msgId ?? this.msgId,
        groupId: groupId ?? this.groupId,
        fromUser: fromUser ?? this.fromUser,
        time: time ?? this.time,
        content: content.present ? content.value : this.content,
        media: media.present ? media.value : this.media,
        replyTo: replyTo.present ? replyTo.value : this.replyTo,
      );
  @override
  String toString() {
    return (StringBuffer('GroupChatMessage(')
          ..write('msgId: $msgId, ')
          ..write('groupId: $groupId, ')
          ..write('fromUser: $fromUser, ')
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
          groupId.hashCode,
          $mrjc(
              fromUser.hashCode,
              $mrjc(
                  time.hashCode,
                  $mrjc(content.hashCode,
                      $mrjc(media.hashCode, replyTo.hashCode)))))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupChatMessage &&
          other.msgId == this.msgId &&
          other.groupId == this.groupId &&
          other.fromUser == this.fromUser &&
          other.time == this.time &&
          other.content == this.content &&
          other.media == this.media &&
          other.replyTo == this.replyTo);
}

class GroupChatMessagesCompanion extends UpdateCompanion<GroupChatMessage> {
  final Value<String> msgId;
  final Value<String> groupId;
  final Value<String> fromUser;
  final Value<DateTime> time;
  final Value<String?> content;
  final Value<String?> media;
  final Value<String?> replyTo;
  const GroupChatMessagesCompanion({
    this.msgId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.fromUser = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.media = const Value.absent(),
    this.replyTo = const Value.absent(),
  });
  GroupChatMessagesCompanion.insert({
    required String msgId,
    required String groupId,
    required String fromUser,
    required DateTime time,
    this.content = const Value.absent(),
    this.media = const Value.absent(),
    this.replyTo = const Value.absent(),
  })  : msgId = Value(msgId),
        groupId = Value(groupId),
        fromUser = Value(fromUser),
        time = Value(time);
  static Insertable<GroupChatMessage> custom({
    Expression<String>? msgId,
    Expression<String>? groupId,
    Expression<String>? fromUser,
    Expression<DateTime>? time,
    Expression<String?>? content,
    Expression<String?>? media,
    Expression<String?>? replyTo,
  }) {
    return RawValuesInsertable({
      if (msgId != null) 'msgId': msgId,
      if (groupId != null) 'groupId': groupId,
      if (fromUser != null) 'fromUser': fromUser,
      if (time != null) 'time': time,
      if (content != null) 'content': content,
      if (media != null) 'media': media,
      if (replyTo != null) 'replyTo': replyTo,
    });
  }

  GroupChatMessagesCompanion copyWith(
      {Value<String>? msgId,
      Value<String>? groupId,
      Value<String>? fromUser,
      Value<DateTime>? time,
      Value<String?>? content,
      Value<String?>? media,
      Value<String?>? replyTo}) {
    return GroupChatMessagesCompanion(
      msgId: msgId ?? this.msgId,
      groupId: groupId ?? this.groupId,
      fromUser: fromUser ?? this.fromUser,
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
      map['msgId'] = Variable<String>(msgId.value);
    }
    if (groupId.present) {
      map['groupId'] = Variable<String>(groupId.value);
    }
    if (fromUser.present) {
      map['fromUser'] = Variable<String>(fromUser.value);
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
      map['replyTo'] = Variable<String?>(replyTo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupChatMessagesCompanion(')
          ..write('msgId: $msgId, ')
          ..write('groupId: $groupId, ')
          ..write('fromUser: $fromUser, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('media: $media, ')
          ..write('replyTo: $replyTo')
          ..write(')'))
        .toString();
  }
}

class GroupChatMessages extends Table
    with TableInfo<GroupChatMessages, GroupChatMessage> {
  final GeneratedDatabase _db;
  final String? _alias;
  GroupChatMessages(this._db, [this._alias]);
  final VerificationMeta _msgIdMeta = const VerificationMeta('msgId');
  late final GeneratedColumn<String?> msgId = GeneratedColumn<String?>(
      'msgId', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  final VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  late final GeneratedColumn<String?> groupId = GeneratedColumn<String?>(
      'groupId', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES GroupDMs(groupId)');
  final VerificationMeta _fromUserMeta = const VerificationMeta('fromUser');
  late final GeneratedColumn<String?> fromUser = GeneratedColumn<String?>(
      'fromUser', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES Users(userId)');
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
  late final GeneratedColumn<String?> replyTo = GeneratedColumn<String?>(
      'replyTo', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false, $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [msgId, groupId, fromUser, time, content, media, replyTo];
  @override
  String get aliasedName => _alias ?? 'GroupChatMessages';
  @override
  String get actualTableName => 'GroupChatMessages';
  @override
  VerificationContext validateIntegrity(Insertable<GroupChatMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('msgId')) {
      context.handle(
          _msgIdMeta, msgId.isAcceptableOrUnknown(data['msgId']!, _msgIdMeta));
    } else if (isInserting) {
      context.missing(_msgIdMeta);
    }
    if (data.containsKey('groupId')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['groupId']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('fromUser')) {
      context.handle(_fromUserMeta,
          fromUser.isAcceptableOrUnknown(data['fromUser']!, _fromUserMeta));
    } else if (isInserting) {
      context.missing(_fromUserMeta);
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
  GroupChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    return GroupChatMessage.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  GroupChatMessages createAlias(String alias) {
    return GroupChatMessages(_db, alias);
  }

  @override
  List<String> get customConstraints => const [
        'CONSTRAINT hasData CHECK (content IS NOT NULL OR media IS NOT NULL)'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class ChatMessagesTextIndexData extends DataClass
    implements Insertable<ChatMessagesTextIndexData> {
  final String msgId;
  final String fromUser;
  final String toUser;
  final String time;
  final String content;
  final String media;
  final String replyTo;
  ChatMessagesTextIndexData(
      {required this.msgId,
      required this.fromUser,
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
      msgId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}msgId'])!,
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
    map['msgId'] = Variable<String>(msgId);
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
      msgId: Value(msgId),
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
      msgId: serializer.fromJson<String>(json['msgId']),
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
      'msgId': serializer.toJson<String>(msgId),
      'fromUser': serializer.toJson<String>(fromUser),
      'toUser': serializer.toJson<String>(toUser),
      'time': serializer.toJson<String>(time),
      'content': serializer.toJson<String>(content),
      'media': serializer.toJson<String>(media),
      'replyTo': serializer.toJson<String>(replyTo),
    };
  }

  ChatMessagesTextIndexData copyWith(
          {String? msgId,
          String? fromUser,
          String? toUser,
          String? time,
          String? content,
          String? media,
          String? replyTo}) =>
      ChatMessagesTextIndexData(
        msgId: msgId ?? this.msgId,
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
      (other is ChatMessagesTextIndexData &&
          other.msgId == this.msgId &&
          other.fromUser == this.fromUser &&
          other.toUser == this.toUser &&
          other.time == this.time &&
          other.content == this.content &&
          other.media == this.media &&
          other.replyTo == this.replyTo);
}

class ChatMessagesTextIndexCompanion
    extends UpdateCompanion<ChatMessagesTextIndexData> {
  final Value<String> msgId;
  final Value<String> fromUser;
  final Value<String> toUser;
  final Value<String> time;
  final Value<String> content;
  final Value<String> media;
  final Value<String> replyTo;
  const ChatMessagesTextIndexCompanion({
    this.msgId = const Value.absent(),
    this.fromUser = const Value.absent(),
    this.toUser = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.media = const Value.absent(),
    this.replyTo = const Value.absent(),
  });
  ChatMessagesTextIndexCompanion.insert({
    required String msgId,
    required String fromUser,
    required String toUser,
    required String time,
    required String content,
    required String media,
    required String replyTo,
  })  : msgId = Value(msgId),
        fromUser = Value(fromUser),
        toUser = Value(toUser),
        time = Value(time),
        content = Value(content),
        media = Value(media),
        replyTo = Value(replyTo);
  static Insertable<ChatMessagesTextIndexData> custom({
    Expression<String>? msgId,
    Expression<String>? fromUser,
    Expression<String>? toUser,
    Expression<String>? time,
    Expression<String>? content,
    Expression<String>? media,
    Expression<String>? replyTo,
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

  ChatMessagesTextIndexCompanion copyWith(
      {Value<String>? msgId,
      Value<String>? fromUser,
      Value<String>? toUser,
      Value<String>? time,
      Value<String>? content,
      Value<String>? media,
      Value<String>? replyTo}) {
    return ChatMessagesTextIndexCompanion(
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
      map['msgId'] = Variable<String>(msgId.value);
    }
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

class ChatMessagesTextIndex extends Table
    with
        TableInfo<ChatMessagesTextIndex, ChatMessagesTextIndexData>,
        VirtualTableInfo<ChatMessagesTextIndex, ChatMessagesTextIndexData> {
  final GeneratedDatabase _db;
  final String? _alias;
  ChatMessagesTextIndex(this._db, [this._alias]);
  final VerificationMeta _msgIdMeta = const VerificationMeta('msgId');
  late final GeneratedColumn<String?> msgId = GeneratedColumn<String?>(
      'msgId', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
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
      [msgId, fromUser, toUser, time, content, media, replyTo];
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
    if (data.containsKey('msgId')) {
      context.handle(
          _msgIdMeta, msgId.isAcceptableOrUnknown(data['msgId']!, _msgIdMeta));
    } else if (isInserting) {
      context.missing(_msgIdMeta);
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
      'fts5(msgId UNINDEXED, fromUser UNINDEXED, toUser UNINDEXED, time UNINDEXED, content, media UNINDEXED, replyTo UNINDEXED, content=\'ChatMessages\', content_rowid=\'rowid\', tokenize = \'porter unicode61\')';
}

class GroupChatMessagesTextIndexData extends DataClass
    implements Insertable<GroupChatMessagesTextIndexData> {
  final String msgId;
  final String groupId;
  final String fromUser;
  final String time;
  final String content;
  final String media;
  final String replyTo;
  GroupChatMessagesTextIndexData(
      {required this.msgId,
      required this.groupId,
      required this.fromUser,
      required this.time,
      required this.content,
      required this.media,
      required this.replyTo});
  factory GroupChatMessagesTextIndexData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return GroupChatMessagesTextIndexData(
      msgId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}msgId'])!,
      groupId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}groupId'])!,
      fromUser: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}fromUser'])!,
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
    map['msgId'] = Variable<String>(msgId);
    map['groupId'] = Variable<String>(groupId);
    map['fromUser'] = Variable<String>(fromUser);
    map['time'] = Variable<String>(time);
    map['content'] = Variable<String>(content);
    map['media'] = Variable<String>(media);
    map['replyTo'] = Variable<String>(replyTo);
    return map;
  }

  GroupChatMessagesTextIndexCompanion toCompanion(bool nullToAbsent) {
    return GroupChatMessagesTextIndexCompanion(
      msgId: Value(msgId),
      groupId: Value(groupId),
      fromUser: Value(fromUser),
      time: Value(time),
      content: Value(content),
      media: Value(media),
      replyTo: Value(replyTo),
    );
  }

  factory GroupChatMessagesTextIndexData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return GroupChatMessagesTextIndexData(
      msgId: serializer.fromJson<String>(json['msgId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      fromUser: serializer.fromJson<String>(json['fromUser']),
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
      'msgId': serializer.toJson<String>(msgId),
      'groupId': serializer.toJson<String>(groupId),
      'fromUser': serializer.toJson<String>(fromUser),
      'time': serializer.toJson<String>(time),
      'content': serializer.toJson<String>(content),
      'media': serializer.toJson<String>(media),
      'replyTo': serializer.toJson<String>(replyTo),
    };
  }

  GroupChatMessagesTextIndexData copyWith(
          {String? msgId,
          String? groupId,
          String? fromUser,
          String? time,
          String? content,
          String? media,
          String? replyTo}) =>
      GroupChatMessagesTextIndexData(
        msgId: msgId ?? this.msgId,
        groupId: groupId ?? this.groupId,
        fromUser: fromUser ?? this.fromUser,
        time: time ?? this.time,
        content: content ?? this.content,
        media: media ?? this.media,
        replyTo: replyTo ?? this.replyTo,
      );
  @override
  String toString() {
    return (StringBuffer('GroupChatMessagesTextIndexData(')
          ..write('msgId: $msgId, ')
          ..write('groupId: $groupId, ')
          ..write('fromUser: $fromUser, ')
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
          groupId.hashCode,
          $mrjc(
              fromUser.hashCode,
              $mrjc(
                  time.hashCode,
                  $mrjc(content.hashCode,
                      $mrjc(media.hashCode, replyTo.hashCode)))))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupChatMessagesTextIndexData &&
          other.msgId == this.msgId &&
          other.groupId == this.groupId &&
          other.fromUser == this.fromUser &&
          other.time == this.time &&
          other.content == this.content &&
          other.media == this.media &&
          other.replyTo == this.replyTo);
}

class GroupChatMessagesTextIndexCompanion
    extends UpdateCompanion<GroupChatMessagesTextIndexData> {
  final Value<String> msgId;
  final Value<String> groupId;
  final Value<String> fromUser;
  final Value<String> time;
  final Value<String> content;
  final Value<String> media;
  final Value<String> replyTo;
  const GroupChatMessagesTextIndexCompanion({
    this.msgId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.fromUser = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.media = const Value.absent(),
    this.replyTo = const Value.absent(),
  });
  GroupChatMessagesTextIndexCompanion.insert({
    required String msgId,
    required String groupId,
    required String fromUser,
    required String time,
    required String content,
    required String media,
    required String replyTo,
  })  : msgId = Value(msgId),
        groupId = Value(groupId),
        fromUser = Value(fromUser),
        time = Value(time),
        content = Value(content),
        media = Value(media),
        replyTo = Value(replyTo);
  static Insertable<GroupChatMessagesTextIndexData> custom({
    Expression<String>? msgId,
    Expression<String>? groupId,
    Expression<String>? fromUser,
    Expression<String>? time,
    Expression<String>? content,
    Expression<String>? media,
    Expression<String>? replyTo,
  }) {
    return RawValuesInsertable({
      if (msgId != null) 'msgId': msgId,
      if (groupId != null) 'groupId': groupId,
      if (fromUser != null) 'fromUser': fromUser,
      if (time != null) 'time': time,
      if (content != null) 'content': content,
      if (media != null) 'media': media,
      if (replyTo != null) 'replyTo': replyTo,
    });
  }

  GroupChatMessagesTextIndexCompanion copyWith(
      {Value<String>? msgId,
      Value<String>? groupId,
      Value<String>? fromUser,
      Value<String>? time,
      Value<String>? content,
      Value<String>? media,
      Value<String>? replyTo}) {
    return GroupChatMessagesTextIndexCompanion(
      msgId: msgId ?? this.msgId,
      groupId: groupId ?? this.groupId,
      fromUser: fromUser ?? this.fromUser,
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
      map['msgId'] = Variable<String>(msgId.value);
    }
    if (groupId.present) {
      map['groupId'] = Variable<String>(groupId.value);
    }
    if (fromUser.present) {
      map['fromUser'] = Variable<String>(fromUser.value);
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
    return (StringBuffer('GroupChatMessagesTextIndexCompanion(')
          ..write('msgId: $msgId, ')
          ..write('groupId: $groupId, ')
          ..write('fromUser: $fromUser, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('media: $media, ')
          ..write('replyTo: $replyTo')
          ..write(')'))
        .toString();
  }
}

class GroupChatMessagesTextIndex extends Table
    with
        TableInfo<GroupChatMessagesTextIndex, GroupChatMessagesTextIndexData>,
        VirtualTableInfo<GroupChatMessagesTextIndex,
            GroupChatMessagesTextIndexData> {
  final GeneratedDatabase _db;
  final String? _alias;
  GroupChatMessagesTextIndex(this._db, [this._alias]);
  final VerificationMeta _msgIdMeta = const VerificationMeta('msgId');
  late final GeneratedColumn<String?> msgId = GeneratedColumn<String?>(
      'msgId', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
  final VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  late final GeneratedColumn<String?> groupId = GeneratedColumn<String?>(
      'groupId', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true, $customConstraints: '');
  final VerificationMeta _fromUserMeta = const VerificationMeta('fromUser');
  late final GeneratedColumn<String?> fromUser = GeneratedColumn<String?>(
      'fromUser', aliasedName, false,
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
      [msgId, groupId, fromUser, time, content, media, replyTo];
  @override
  String get aliasedName => _alias ?? 'GroupChatMessagesTextIndex';
  @override
  String get actualTableName => 'GroupChatMessagesTextIndex';
  @override
  VerificationContext validateIntegrity(
      Insertable<GroupChatMessagesTextIndexData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('msgId')) {
      context.handle(
          _msgIdMeta, msgId.isAcceptableOrUnknown(data['msgId']!, _msgIdMeta));
    } else if (isInserting) {
      context.missing(_msgIdMeta);
    }
    if (data.containsKey('groupId')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['groupId']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('fromUser')) {
      context.handle(_fromUserMeta,
          fromUser.isAcceptableOrUnknown(data['fromUser']!, _fromUserMeta));
    } else if (isInserting) {
      context.missing(_fromUserMeta);
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
  GroupChatMessagesTextIndexData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    return GroupChatMessagesTextIndexData.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  GroupChatMessagesTextIndex createAlias(String alias) {
    return GroupChatMessagesTextIndex(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(msgId UNINDEXED, groupId UNINDEXED, fromUser UNINDEXED, time UNINDEXED, content, media UNINDEXED, replyTo UNINDEXED, content=\'GroupChatMessages\', content_rowid=\'rowid\', tokenize = \'porter unicode61\')';
}

class GroupUserMappingData extends DataClass
    implements Insertable<GroupUserMappingData> {
  final String groupId;
  final String userId;
  GroupUserMappingData({required this.groupId, required this.userId});
  factory GroupUserMappingData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return GroupUserMappingData(
      groupId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}groupId'])!,
      userId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}userId'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['groupId'] = Variable<String>(groupId);
    map['userId'] = Variable<String>(userId);
    return map;
  }

  GroupUserMappingCompanion toCompanion(bool nullToAbsent) {
    return GroupUserMappingCompanion(
      groupId: Value(groupId),
      userId: Value(userId),
    );
  }

  factory GroupUserMappingData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return GroupUserMappingData(
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
    };
  }

  GroupUserMappingData copyWith({String? groupId, String? userId}) =>
      GroupUserMappingData(
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
      );
  @override
  String toString() {
    return (StringBuffer('GroupUserMappingData(')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(groupId.hashCode, userId.hashCode));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupUserMappingData &&
          other.groupId == this.groupId &&
          other.userId == this.userId);
}

class GroupUserMappingCompanion extends UpdateCompanion<GroupUserMappingData> {
  final Value<String> groupId;
  final Value<String> userId;
  const GroupUserMappingCompanion({
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
  });
  GroupUserMappingCompanion.insert({
    required String groupId,
    required String userId,
  })  : groupId = Value(groupId),
        userId = Value(userId);
  static Insertable<GroupUserMappingData> custom({
    Expression<String>? groupId,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'groupId': groupId,
      if (userId != null) 'userId': userId,
    });
  }

  GroupUserMappingCompanion copyWith(
      {Value<String>? groupId, Value<String>? userId}) {
    return GroupUserMappingCompanion(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['groupId'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['userId'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupUserMappingCompanion(')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

class GroupUserMapping extends Table
    with TableInfo<GroupUserMapping, GroupUserMappingData> {
  final GeneratedDatabase _db;
  final String? _alias;
  GroupUserMapping(this._db, [this._alias]);
  final VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  late final GeneratedColumn<String?> groupId = GeneratedColumn<String?>(
      'groupId', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES GroupDMs(groupId)');
  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String?> userId = GeneratedColumn<String?>(
      'userId', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES Users(userId)');
  @override
  List<GeneratedColumn> get $columns => [groupId, userId];
  @override
  String get aliasedName => _alias ?? 'GroupUserMapping';
  @override
  String get actualTableName => 'GroupUserMapping';
  @override
  VerificationContext validateIntegrity(
      Insertable<GroupUserMappingData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('groupId')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['groupId']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('userId')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['userId']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, userId};
  @override
  GroupUserMappingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return GroupUserMappingData.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  GroupUserMapping createAlias(String alias) {
    return GroupUserMapping(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(groupId, userId)'];
  @override
  bool get dontWriteConstraints => true;
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$AppDb.connect(DatabaseConnection c) : super.connect(c);
  late final Users users = Users(this);
  late final ChatMessages chatMessages = ChatMessages(this);
  late final Index fromUserIndex = Index(
      'fromUserIndex', 'CREATE INDEX fromUserIndex ON ChatMessages (fromUser)');
  late final Index toUserIndex =
      Index('toUserIndex', 'CREATE INDEX toUserIndex ON ChatMessages (toUser)');
  late final GroupDMs groupDMs = GroupDMs(this);
  late final GroupChatMessages groupChatMessages = GroupChatMessages(this);
  late final Index groupIndex = Index(
      'groupIndex', 'CREATE INDEX groupIndex ON GroupChatMessages (groupID)');
  late final ChatMessagesTextIndex chatMessagesTextIndex =
      ChatMessagesTextIndex(this);
  late final Trigger chatMessagesTextIndexAI = Trigger(
      'CREATE TRIGGER ChatMessagesTextIndex_AI AFTER INSERT ON ChatMessages BEGIN INSERT INTO ChatMessagesTextIndex ("rowid", msgId, fromUser, toUser, time, content, media, replyTo) VALUES (new."rowid", new.msgId, new.fromUser, new.toUser, new.time, new.content, new.media, new.replyTo);END',
      'ChatMessagesTextIndex_AI');
  late final Trigger chatMessagesTextIndexAD = Trigger(
      'CREATE TRIGGER ChatMessagesTextIndex_AD AFTER DELETE ON ChatMessages BEGIN INSERT INTO ChatMessagesTextIndex (ChatMessagesTextIndex, "rowid", msgId, fromUser, toUser, time, content, media, replyTo) VALUES (\'delete\', old."rowid", old.msgId, old.fromUser, old.toUser, old.time, old.content, old.media, old.replyTo);END',
      'ChatMessagesTextIndex_AD');
  late final Trigger chatMessagesTextIndexAU = Trigger(
      'CREATE TRIGGER ChatMessagesTextIndex_AU AFTER UPDATE ON ChatMessages BEGIN INSERT INTO ChatMessagesTextIndex (ChatMessagesTextIndex, "rowid", msgId, fromUser, toUser, time, content, media, replyTo) VALUES (\'delete\', old."rowid", old.msgId, old.fromUser, old.toUser, old.time, old.content, old.media, old.replyTo);INSERT INTO ChatMessagesTextIndex ("rowid", msgId, fromUser, toUser, time, content, media, replyTo) VALUES (new."rowid", new.msgId, new.fromUser, new.toUser, new.time, new.content, new.media, new.replyTo);END',
      'ChatMessagesTextIndex_AU');
  late final GroupChatMessagesTextIndex groupChatMessagesTextIndex =
      GroupChatMessagesTextIndex(this);
  late final Trigger groupChatMessagesTextIndexAI = Trigger(
      'CREATE TRIGGER GroupChatMessagesTextIndex_AI AFTER INSERT ON GroupChatMessages BEGIN INSERT INTO GroupChatMessagesTextIndex ("rowid", msgId, groupId, fromUser, time, content, media, replyTo) VALUES (new."rowid", new.msgId, new.groupId, new.fromUser, new.time, new.content, new.media, new.replyTo);END',
      'GroupChatMessagesTextIndex_AI');
  late final Trigger groupChatMessagesTextIndexAD = Trigger(
      'CREATE TRIGGER GroupChatMessagesTextIndex_AD AFTER DELETE ON GroupChatMessages BEGIN INSERT INTO GroupChatMessagesTextIndex (GroupChatMessagesTextIndex, "rowid", msgId, groupId, fromUser, time, content, media, replyTo) VALUES (\'delete\', old."rowid", old.msgId, old.groupId, old.fromUser, old.time, old.content, old.media, old.replyTo);END',
      'GroupChatMessagesTextIndex_AD');
  late final Trigger groupChatMessagesTextIndexAU = Trigger(
      'CREATE TRIGGER GroupChatMessagesTextIndex_AU AFTER UPDATE ON GroupChatMessages BEGIN INSERT INTO GroupChatMessagesTextIndex (GroupChatMessagesTextIndex, "rowid", msgId, groupId, fromUser, time, content, media, replyTo) VALUES (\'delete\', old."rowid", old.msgId, old.groupId, old.fromUser, old.time, old.content, old.media, old.replyTo);INSERT INTO GroupChatMessagesTextIndex ("rowid", msgId, groupId, fromUser, time, content, media, replyTo) VALUES (new."rowid", new.msgId, new.groupId, new.fromUser, new.time, new.content, new.media, new.replyTo);END',
      'GroupChatMessagesTextIndex_AU');
  late final GroupUserMapping groupUserMapping = GroupUserMapping(this);
  Future<int> addUser(
      {required String userId,
      required String name,
      String? about,
      String? profileImg}) {
    return customInsert(
      'INSERT INTO Users VALUES (:userId, :name, :about, :profileImg)',
      variables: [
        Variable<String>(userId),
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

  Selectable<User> getUsersNameMatching({required String match}) {
    return customSelect(
        'SELECT * FROM Users WHERE LOWER(name) LIKE \'%\' || :match || \'%\'',
        variables: [
          Variable<String>(match)
        ],
        readsFrom: {
          users,
        }).map(users.mapFromRow);
  }

  Future<int> createGroup(
      {required String groupId,
      required String name,
      String? description,
      String? groupIcon}) {
    return customInsert(
      'INSERT INTO GroupDMs VALUES (:groupId, :name, :description, :groupIcon)',
      variables: [
        Variable<String>(groupId),
        Variable<String>(name),
        Variable<String?>(description),
        Variable<String?>(groupIcon)
      ],
      updates: {groupDMs},
    );
  }

  Selectable<GroupDM> getGroupsNameMatching({required String match}) {
    return customSelect(
        'SELECT * FROM GroupDMs WHERE LOWER(name) LIKE \'%\' || :match || \'%\'',
        variables: [
          Variable<String>(match)
        ],
        readsFrom: {
          groupDMs,
        }).map(groupDMs.mapFromRow);
  }

  Future<int> addUserToGroup(
      {required String groupId, required String userId}) {
    return customInsert(
      'INSERT INTO GroupUserMapping VALUES (:groupId, :userId)',
      variables: [Variable<String>(groupId), Variable<String>(userId)],
      updates: {groupUserMapping},
    );
  }

  Selectable<GroupDM> getGroupsOfUser({required String userID}) {
    return customSelect(
        'SELECT DISTINCT G.groupId, G.name, G.description, G.groupIcon FROM GroupDMs AS G,GroupUserMapping AS GM WHERE GM.userId == :userID',
        variables: [
          Variable<String>(userID)
        ],
        readsFrom: {
          groupDMs,
          groupUserMapping,
        }).map(groupDMs.mapFromRow);
  }

  Selectable<User> getGroupMembers({required String groupID}) {
    return customSelect(
        'SELECT U.* FROM Users AS U,(SELECT DISTINCT userId FROM GroupUserMapping AS GM WHERE GM.groupId == :groupID) AS UID WHERE U.userId == UID.userId',
        variables: [
          Variable<String>(groupID)
        ],
        readsFrom: {
          users,
          groupUserMapping,
        }).map(users.mapFromRow);
  }

  Selectable<GroupChatMessage> getGroupChat({required String groupId}) {
    return customSelect(
        'SELECT * FROM GroupChatMessages WHERE groupId = :groupId ORDER BY msgId',
        variables: [
          Variable<String>(groupId)
        ],
        readsFrom: {
          groupChatMessages,
        }).map(groupChatMessages.mapFromRow);
  }

  Future<int> insertGroupChatMessage(
      {required String msgId,
      required String groupId,
      required String fromUser,
      required DateTime time,
      String? content,
      String? media,
      String? replyTo}) {
    return customInsert(
      'INSERT INTO GroupChatMessages VALUES (:msgId, :groupId, :fromUser, :time, :content, :media, :replyTo)',
      variables: [
        Variable<String>(msgId),
        Variable<String>(groupId),
        Variable<String>(fromUser),
        Variable<DateTime>(time),
        Variable<String?>(content),
        Variable<String?>(media),
        Variable<String?>(replyTo)
      ],
      updates: {groupChatMessages},
    );
  }

  Selectable<ChatMessage> getUserChat({required String otherUser}) {
    return customSelect(
        'SELECT * FROM ChatMessages WHERE fromUser = :otherUser OR toUser = :otherUser ORDER BY msgId',
        variables: [
          Variable<String>(otherUser)
        ],
        readsFrom: {
          chatMessages,
        }).map(chatMessages.mapFromRow);
  }

  Future<int> insertMessage(
      {required String msgId,
      required String fromUser,
      required String toUser,
      required DateTime time,
      String? content,
      String? media,
      String? replyTo}) {
    return customInsert(
      'INSERT INTO ChatMessages VALUES (:msgId, :fromUser, :toUser, :time, :content, :media, :replyTo)',
      variables: [
        Variable<String>(msgId),
        Variable<String>(fromUser),
        Variable<String>(toUser),
        Variable<DateTime>(time),
        Variable<String?>(content),
        Variable<String?>(media),
        Variable<String?>(replyTo)
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
        userId: row.read<String>('userId'),
        name: row.read<String>('name'),
        about: row.read<String?>('about'),
        profileImg: row.read<String?>('profileImg'),
      );
    });
  }

  Selectable<SearchGroupChatMessagesResult> searchGroupChatMessages(
      {required String query, int? limit}) {
    return customSelect(
        'SELECT c.content, g.* FROM GroupDMs AS g JOIN (SELECT groupId, content FROM GroupChatMessagesTextIndex WHERE content MATCH :query ORDER BY rank LIMIT :limit) AS c ON c.groupId = g.groupId',
        variables: [
          Variable<String>(query),
          Variable<int?>(limit)
        ],
        readsFrom: {
          groupDMs,
          groupChatMessagesTextIndex,
        }).map((QueryRow row) {
      return SearchGroupChatMessagesResult(
        content: row.read<String>('content'),
        groupId: row.read<String>('groupId'),
        name: row.read<String>('name'),
        description: row.read<String?>('description'),
        groupIcon: row.read<String?>('groupIcon'),
      );
    });
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        chatMessages,
        fromUserIndex,
        toUserIndex,
        groupDMs,
        groupChatMessages,
        groupIndex,
        chatMessagesTextIndex,
        chatMessagesTextIndexAI,
        chatMessagesTextIndexAD,
        chatMessagesTextIndexAU,
        groupChatMessagesTextIndex,
        groupChatMessagesTextIndexAI,
        groupChatMessagesTextIndexAD,
        groupChatMessagesTextIndexAU,
        groupUserMapping
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
          WritePropagation(
            on: TableUpdateQuery.onTableName('GroupChatMessages',
                limitUpdateKind: UpdateKind.insert),
            result: [
              TableUpdate('GroupChatMessagesTextIndex',
                  kind: UpdateKind.insert),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('GroupChatMessages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('GroupChatMessagesTextIndex',
                  kind: UpdateKind.insert),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('GroupChatMessages',
                limitUpdateKind: UpdateKind.update),
            result: [
              TableUpdate('GroupChatMessagesTextIndex',
                  kind: UpdateKind.insert),
            ],
          ),
        ],
      );
}

class SearchChatMessagesResult {
  final String content;
  final String userId;
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

class SearchGroupChatMessagesResult {
  final String content;
  final String groupId;
  final String name;
  final String? description;
  final String? groupIcon;
  SearchGroupChatMessagesResult({
    required this.content,
    required this.groupId,
    required this.name,
    this.description,
    this.groupIcon,
  });
}
