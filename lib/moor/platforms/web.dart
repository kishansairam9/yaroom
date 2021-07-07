import 'package:moor/moor_web.dart';

import '../db.dart';

AppDb constructDb({bool logStatements = false, bool removeExisting = false}) {
  return AppDb(WebDatabase('db', logStatements: logStatements));
}
