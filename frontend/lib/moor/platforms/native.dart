import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';

import 'package:path_provider/path_provider.dart' as paths;
import 'package:path/path.dart' as p;

import '../db.dart';

AppDb constructDb({bool logStatements = false, bool removeExisting = false}) {
  if (Platform.isIOS || Platform.isAndroid) {
    final executor = LazyDatabase(() async {
      final dataDir = await paths.getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dataDir.path, 'db.sqlite'));
      if (removeExisting && dbFile.existsSync()) {
        dbFile.deleteSync();
      }
      return VmDatabase(dbFile, logStatements: logStatements);
    });
    return AppDb(executor);
  }
  if (Platform.isMacOS || Platform.isLinux) {
    final file = File('db.sqlite');
    if (removeExisting && file.existsSync()) {
      file.deleteSync();
    }
    return AppDb(VmDatabase(file, logStatements: logStatements));
  }
  // if (Platform.isWindows) {
  //   final file = File('db.sqlite');
  //   return Database(VMDatabase(file, logStatements: logStatements));
  // }
  return AppDb(VmDatabase.memory(logStatements: logStatements));
}
