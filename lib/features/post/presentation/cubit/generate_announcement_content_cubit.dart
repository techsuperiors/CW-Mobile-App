import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/generate_announcement_content_usecase.dart';

enum GenerateAnnouncementContentStatus { initial, loading, success, error }

class GenerateAnnouncementContentState extends Equatable {
  final GenerateAnnouncementContentStatus status;
  final String content;
  final String message;

  const GenerateAnnouncementContentState({
    this.status = GenerateAnnouncementContentStatus.initial,
    this.content = '',
    this.message = '',
  });

  GenerateAnnouncementContentState copyWith({
    GenerateAnnouncementContentStatus? status,
    String? content,
    String? message,
  }) {
    return GenerateAnnouncementContentState(
      status: status ?? this.status,
      content: content ?? this.content,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, content, message];
}

class GenerateAnnouncementContentCubit
    extends Cubit<GenerateAnnouncementContentState> {
  final GenerateAnnouncementContentUseCase generateAnnouncementContentUseCase;

  GenerateAnnouncementContentCubit({
    required this.generateAnnouncementContentUseCase,
  }) : super(const GenerateAnnouncementContentState());

  Future<void> generate({required String content}) async {
    emit(
      state.copyWith(
        status: GenerateAnnouncementContentStatus.loading,
        message: '',
      ),
    );

    final result = await generateAnnouncementContentUseCase(content: content);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GenerateAnnouncementContentStatus.error,
          message: failure.message,
        ),
      ),
      (generatedContent) => emit(
        state.copyWith(
          status: GenerateAnnouncementContentStatus.success,
          content: generatedContent,
          message: '',
        ),
      ),
    );
  }
}
