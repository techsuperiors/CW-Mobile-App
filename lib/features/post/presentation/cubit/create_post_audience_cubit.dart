import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/create_post_audience_entity.dart';
import '../../domain/usecases/get_create_post_audience_departments_usecase.dart';
import '../../domain/usecases/get_create_post_audience_users_usecase.dart';

enum CreatePostAudienceStatus { initial, loading, loaded, error }

class CreatePostAudienceState extends Equatable {
  final CreatePostAudienceStatus status;
  final List<CreatePostAudienceDepartmentEntity> departments;
  final List<CreatePostAudienceUserEntity> users;
  final bool allUsersSelected;
  final bool departmentsSelected;
  final bool individualsSelected;
  final List<int> selectedDepartmentIds;
  final List<int> selectedIndividualUserIds;
  final List<int> excludedUserIds;
  final String errorMessage;

  const CreatePostAudienceState({
    this.status = CreatePostAudienceStatus.initial,
    this.departments = const [],
    this.users = const [],
    this.allUsersSelected = false,
    this.departmentsSelected = false,
    this.individualsSelected = false,
    this.selectedDepartmentIds = const [],
    this.selectedIndividualUserIds = const [],
    this.excludedUserIds = const [],
    this.errorMessage = '',
  });

  CreatePostAudienceState copyWith({
    CreatePostAudienceStatus? status,
    List<CreatePostAudienceDepartmentEntity>? departments,
    List<CreatePostAudienceUserEntity>? users,
    bool? allUsersSelected,
    bool? departmentsSelected,
    bool? individualsSelected,
    List<int>? selectedDepartmentIds,
    List<int>? selectedIndividualUserIds,
    List<int>? excludedUserIds,
    String? errorMessage,
  }) {
    return CreatePostAudienceState(
      status: status ?? this.status,
      departments: departments ?? this.departments,
      users: users ?? this.users,
      allUsersSelected: allUsersSelected ?? this.allUsersSelected,
      departmentsSelected: departmentsSelected ?? this.departmentsSelected,
      individualsSelected: individualsSelected ?? this.individualsSelected,
      selectedDepartmentIds:
          selectedDepartmentIds ?? this.selectedDepartmentIds,
      selectedIndividualUserIds:
          selectedIndividualUserIds ?? this.selectedIndividualUserIds,
      excludedUserIds: excludedUserIds ?? this.excludedUserIds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    departments,
    users,
    allUsersSelected,
    departmentsSelected,
    individualsSelected,
    selectedDepartmentIds,
    selectedIndividualUserIds,
    excludedUserIds,
    errorMessage,
  ];
}

class CreatePostAudienceCubit extends Cubit<CreatePostAudienceState> {
  final GetCreatePostAudienceDepartmentsUseCase
  getCreatePostAudienceDepartmentsUseCase;
  final GetCreatePostAudienceUsersUseCase getCreatePostAudienceUsersUseCase;

  CreatePostAudienceCubit({
    required this.getCreatePostAudienceDepartmentsUseCase,
    required this.getCreatePostAudienceUsersUseCase,
  }) : super(const CreatePostAudienceState());

  Future<void> loadAudienceOptions() async {
    if (state.status == CreatePostAudienceStatus.loading) {
      return;
    }

    if (state.status == CreatePostAudienceStatus.loaded &&
        state.departments.isNotEmpty &&
        state.users.isNotEmpty) {
      return;
    }

    emit(
      state.copyWith(
        status: CreatePostAudienceStatus.loading,
        errorMessage: '',
      ),
    );

    final departmentsResult = await getCreatePostAudienceDepartmentsUseCase();
    final usersResult = await getCreatePostAudienceUsersUseCase();

    departmentsResult.fold(
      (failure) => emit(
        state.copyWith(
          status: CreatePostAudienceStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (departments) {
        usersResult.fold(
          (failure) => emit(
            state.copyWith(
              status: CreatePostAudienceStatus.error,
              errorMessage: failure.message,
            ),
          ),
          (users) => emit(
            state.copyWith(
              status: CreatePostAudienceStatus.loaded,
              departments: departments,
              users: _sortUsers(users),
              errorMessage: '',
            ),
          ),
        );
      },
    );
  }

  void setAllUsersSelected(bool isSelected) {
    if (isSelected) {
      emit(
        state.copyWith(
          allUsersSelected: true,
          departmentsSelected: false,
          individualsSelected: false,
          selectedDepartmentIds: const [],
          selectedIndividualUserIds: const [],
          excludedUserIds: const [],
        ),
      );
      return;
    }

    emit(state.copyWith(allUsersSelected: false, excludedUserIds: const []));
  }

  void setDepartmentsSelected(bool isSelected) {
    emit(
      state.copyWith(
        allUsersSelected: false,
        departmentsSelected: isSelected,
        individualsSelected: false,
        selectedDepartmentIds:
            isSelected ? state.selectedDepartmentIds : const [],
        selectedIndividualUserIds: const [],
        excludedUserIds: const [],
      ),
    );
  }

  void setIndividualsSelected(bool isSelected) {
    emit(
      state.copyWith(
        allUsersSelected: false,
        departmentsSelected: false,
        individualsSelected: isSelected,
        selectedDepartmentIds: const [],
        selectedIndividualUserIds:
            isSelected ? state.selectedIndividualUserIds : const [],
        excludedUserIds: const [],
      ),
    );
  }

  void addDepartment(CreatePostAudienceDepartmentEntity department) {
    final selectedDepartmentIds = {
      ...state.selectedDepartmentIds,
      department.id,
    }.toList(growable: false);
    final memberIds = department.members.map((member) => member.id).toSet();
    final excludedUserIds = state.excludedUserIds
        .where((userId) => !memberIds.contains(userId))
        .toList(growable: false);

    emit(
      state.copyWith(
        allUsersSelected: false,
        departmentsSelected: true,
        selectedDepartmentIds: selectedDepartmentIds,
        excludedUserIds: excludedUserIds,
      ),
    );
  }

  void removeDepartment(int departmentId) {
    emit(
      state.copyWith(
        selectedDepartmentIds: state.selectedDepartmentIds
            .where((id) => id != departmentId)
            .toList(growable: false),
      ),
    );
  }

  void addIndividualUser(CreatePostAudienceUserEntity user) {
    emit(
      state.copyWith(
        allUsersSelected: false,
        individualsSelected: true,
        selectedIndividualUserIds: {
          ...state.selectedIndividualUserIds,
          user.id,
        }.toList(growable: false),
        excludedUserIds: state.excludedUserIds
            .where((userId) => userId != user.id)
            .toList(growable: false),
      ),
    );
  }

  void removeSelectedUser(int userId) {
    if (state.allUsersSelected) {
      emit(
        state.copyWith(
          allUsersSelected: true,
          departmentsSelected: false,
          individualsSelected: false,
          selectedDepartmentIds: const [],
          selectedIndividualUserIds: const [],
          excludedUserIds: {
            ...state.excludedUserIds,
            userId,
          }.toList(growable: false),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedIndividualUserIds: state.selectedIndividualUserIds
            .where((selectedId) => selectedId != userId)
            .toList(growable: false),
        excludedUserIds: {
          ...state.excludedUserIds,
          userId,
        }.toList(growable: false),
      ),
    );
  }

  List<CreatePostAudienceUserEntity> _sortUsers(
    List<CreatePostAudienceUserEntity> users,
  ) {
    final sortedUsers = [...users];
    sortedUsers.sort(
      (first, second) =>
          first.fullName.toLowerCase().compareTo(second.fullName.toLowerCase()),
    );
    return List.unmodifiable(sortedUsers);
  }
}
