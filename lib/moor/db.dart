import 'package:moor/moor.dart';

export 'platforms/shared.dart';

part 'db.g.dart';

@UseMoor(
  include: {'chats.moor', 'data.moor'},
)
class AppDb extends _$AppDb {
  AppDb(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
