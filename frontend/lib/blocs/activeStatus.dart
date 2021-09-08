import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActiveStatusMap {
  late Map<String, ActiveStatusCubit>? statusMap;
  ActiveStatusMap({required this.statusMap});
  update(String user, bool status) {
    statusMap![user]!.setStatus(status: status);
  }

  add(String user) {
    if (!statusMap!.containsKey(user)) {
      statusMap![user] = ActiveStatusCubit(initialState: false);
    }
  }

  ActiveStatusCubit get(String user) {
    if (!statusMap!.containsKey(user)) {
      statusMap![user] = ActiveStatusCubit(initialState: false);
    }
    return statusMap![user]!;
  }
}

class ActiveStatusCubit extends Cubit<bool> {
  ActiveStatusCubit({required bool initialState}) : super(initialState);

  void setStatus({required bool status}) {
    emit(status);
  }
}
