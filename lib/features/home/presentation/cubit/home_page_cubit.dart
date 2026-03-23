import 'package:flutter_bloc/flutter_bloc.dart';

class HomePageCubit extends Cubit<int> {
  HomePageCubit() : super(2); // default tab = 2 (Attendance)

  void switchTab(int index) => emit(index);
}