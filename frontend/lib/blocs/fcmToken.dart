import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FcmTokenCubit extends Cubit<String> {
  FcmTokenCubit() : super('');

  void updateToken(String token) {
    emit(token);
  }
}
