import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

/// Authentication repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<User> login(String username, String password) async {
    try {
      final loginResponse = await remoteDataSource.login(username, password);
      
      // Save the token
      if (loginResponse.token != null) {
        await localDataSource.saveToken(loginResponse.token!);
      }

      // Create a minimal user from the username (since API only returns token)
      // In a real app, you might want to fetch user details after login
      final user = UserModel(
        id: username, // Using username as ID temporarily
        email: username, // Using username as email
        name: username,
        avatar: null,
        role: null,
        createdAt: null,
      );

      await localDataSource.cacheUser(user);
      return user;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
    } catch (e) {
      // Clear local cache even if remote logout fails
      await localDataSource.clearCache();
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      return await localDataSource.getCachedUser();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await localDataSource.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

