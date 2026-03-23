import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_remote_datasource.dart';
import '../models/user_profile_model.dart'
    hide
        UserInfo,
        ReportingManagerInfo,
        ReportingHrInfo,
        UserDepartmentInfo,
        UserDesignationInfo,
        ClientInfo,
        RoleInfo;

/// User Profile repository implementation
class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserProfile>> getUserProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final profileModel = await remoteDataSource.getUserProfile();

        // Convert model to entity
        final profile = _mapModelToEntity(profileModel);

        return Right(profile);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  UserProfile _mapModelToEntity(UserProfileModel model) {
    return UserProfile(
      clientId: model.clientId,
      userId: model.userId,
      departmentId: model.departmentId,
      address: model.address,
      birthday: model.birthday,
      bloodGroup: model.bloodGroup,
      userAbout: model.userAbout,
      reportingHr: model.reportingHr,
      reportingManager: model.reportingManager,
      skills: model.skills,
      esiNumber: model.esiNumber,
      uanNumber: model.uanNumber,
      pfNumber: model.pfNumber,
      ctc: model.ctc,
      payrollEnabled: model.payrollEnabled,
      belongsTo: model.belongsTo,
      employmentStatus: model.employmentStatus,
      familyDetails: model.familyDetails,
      officialPhone: model.officialPhone,
      inProbation: model.inProbation,
      l2Manager: model.l2Manager,
      user: UserInfo(
        id: model.user.id,
        title: model.user.title,
        firstName: model.user.firstName,
        middleName: model.user.middleName,
        lastName: model.user.lastName,
        location: model.user.location,
        email: model.user.email,
        phone: model.user.phone,
        status: model.user.status,
        username: model.user.username,
        personalEmail: model.user.personalEmail,
        imageUrl: model.user.imageUrl,
        gender: model.user.gender,
        joiningDate: model.user.joiningDate,
        employeeType: model.user.employeeType,
        employeeID: model.user.employeeID,
        profileColor: model.user.profileColor,
        coverImageUrl: model.user.coverImageUrl,
        workMode: model.user.workMode,
        maritalStatus: model.user.maritalStatus,
      ),
      reportingManagerInfo:
          model.reportingManagerInfo != null
              ? ReportingManagerInfo(
                firstName: model.reportingManagerInfo!.firstName,
                lastName: model.reportingManagerInfo!.lastName,
                middleName: model.reportingManagerInfo!.middleName,
                email: model.reportingManagerInfo!.email,
                imageUrl: model.reportingManagerInfo!.imageUrl,
                profileColor: model.reportingManagerInfo!.profileColor,
              )
              : null,
      reportingHrInfo:
          model.reportingHrInfo != null
              ? ReportingHrInfo(
                firstName: model.reportingHrInfo!.firstName,
                lastName: model.reportingHrInfo!.lastName,
                middleName: model.reportingHrInfo!.middleName,
                email: model.reportingHrInfo!.email,
                imageUrl: model.reportingHrInfo!.imageUrl,
                profileColor: model.reportingHrInfo!.profileColor,
              )
              : null,
      userDepartment:
          model.userDepartment != null
              ? UserDepartmentInfo(
                departmentName: model.userDepartment!.departmentName,
              )
              : null,
      userDesignation:
          model.userDesignation != null
              ? UserDesignationInfo(
                designationName: model.userDesignation!.designationName,
              )
              : null,
      client:
          model.client != null
              ? ClientInfo(
                id: model.client!.id,
                clientName: model.client!.clientName,
              )
              : null,
      role:
          model.role != null
              ? RoleInfo(
                roleName: model.role!.roleName,
                permissions: model.role!.permissions,
              )
              : null,
    );
  }
}
