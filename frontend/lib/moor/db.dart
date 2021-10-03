import 'package:moor/moor.dart';

export 'platforms/shared.dart';

part 'db.g.dart';

@UseMoor(
  include: {'tables.moor'},
)
class AppDb extends _$AppDb {
  AppDb(QueryExecutor e) : super(e);
  AppDb.connect(DatabaseConnection connection) : super.connect(connection);

  @override
  int get schemaVersion => 1;

  Future deleteAll() async {
    final m = createMigrator();
    for (final table in allTables.toList().reversed) {
      await m.deleteTable(table.actualTableName);
    }
    for (final en in allSchemaEntities.toList().reversed) {
      await m.drop(en);
    }
  }

  Future createAll() async {
    final m = createMigrator();
    m.createAll();
  }
}
