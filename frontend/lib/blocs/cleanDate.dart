import 'package:hydrated_bloc/hydrated_bloc.dart';

class CleanDate {
  late DateTime? time;
  CleanDate({this.time});
}

class CleanDateCubit extends HydratedCubit<CleanDate> {
  CleanDateCubit() : super(CleanDate(time: DateTime.now()));

  @override
  CleanDate fromJson(Map<String, dynamic> json) {
    return CleanDate(time: json['value'] as DateTime);
  }

  @override
  Map<String, dynamic> toJson(CleanDateate) {
    return {'value': state};
  }

  void increment() {
    DateTime time = DateTime.now();
    emit(CleanDate(time: time.add(new Duration(days: 1))));
  }
}
