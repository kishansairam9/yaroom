import 'package:moor/moor.dart';
import 'package:moor/moor_web.dart';
import 'dart:html';

import 'package:moor/remote.dart';

import '../db.dart';

AppDb constructDb({bool logStatements = false, bool removeExisting = false}) {
  final executor = LazyDatabase(() async {
    final storage = await MoorWebStorage.indexedDbIfSupported('db');
    return WebDatabase.withStorage(storage, logStatements: logStatements);
  });
  return AppDb(executor);
  // Worker WASM
  // DatabaseConnection connectToWorker() {
  //   final worker = SharedWorker('worker.dart.js');
  //   return remote(worker.port!.channel());
  // }
  // return AppDb.connect(connectToWorker());
}
