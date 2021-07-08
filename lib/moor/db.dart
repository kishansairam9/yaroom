import 'package:moor/moor.dart';

export 'platforms/shared.dart';

part 'db.g.dart';

@UseMoor(
  include: {'tables.moor'},
)
class AppDb extends _$AppDb {
  AppDb(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
