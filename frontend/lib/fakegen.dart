import 'package:faker/faker.dart';
import 'dart:math';

Function counterClosure(int start) {
  return () {
    start += 1;
    return start;
  };
}

dynamic getUserId = counterClosure(13);
dynamic getMsgId = counterClosure(44000);
dynamic getGroupId = counterClosure(100000);

dynamic getImage() => faker.image.image(
    width: 150, height: 150, keywords: ['people', 'nature'], random: true);

dynamic getGroupImage() => faker.image.image(
    width: 150, height: 150, keywords: ['office', 'corporate'], random: true);

dynamic getName() => faker.person.name();
dynamic getCompanyName() => faker.company.name();

final _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890 ';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

dynamic getAbout() => getRandomString(Random().nextInt(70));

int getRandomInt(int minm, int maxm) => Random().nextInt(maxm) + minm;

dynamic getExchange() {
  final random = Random().nextInt(20) + 1;
  final sender = [];
  final msgs = [];
  for (int i = 0; i < random; i++) {
    sender.add(Random().nextInt(2));
    msgs.add(getRandomString(Random().nextInt(100) + 1));
  }
  return [msgs, sender];
}
