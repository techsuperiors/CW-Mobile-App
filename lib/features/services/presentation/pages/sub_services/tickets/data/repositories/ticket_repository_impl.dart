import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_datasource.dart';
import '../models/ticket_api_model.dart';

/// Ticket repository implementation
class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TicketRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TicketList>> getTicketList(String requestType) async {
    if (await networkInfo.isConnected) {
      try {
        final responseModels = await remoteDataSource.getTicketList(requestType);
        
        // Convert models to entities
        final tickets = responseModels.map((model) {
          return Ticket(
            id: model.id,
            ticketID: model.ticketID,
            priority: model.priority,
            subject: model.subject,
            ticketStatus: model.ticketStatus,
            ticketCategoryId: model.ticketCategoryId,
            ticketSubCategoryId: model.ticketSubCategoryId,
            pinnedBy: model.pinnedBy,
            createdBy: model.createdBy,
            raisedFor: model.raisedFor,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            createdByUser: TicketCreatedBy(
              firstName: model.createdByUser.firstName,
              lastName: model.createdByUser.lastName,
              profileColor: model.createdByUser.profileColor,
              imageUrl: model.createdByUser.imageUrl,
            ),
            categoryName: model.categoryName,
            subcategoryName: model.subcategoryName,
          );
        }).toList();
        
        return Right(TicketList(tickets: tickets));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
        return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, TicketStats>> getTicketStats() async {
    if (await networkInfo.isConnected) {
      try {
        final responseModel = await remoteDataSource.getTicketStats();
        
        final stats = TicketStats(
          open: responseModel.open,
          inProgress: responseModel.inProgress,
          resolved: responseModel.resolved,
          escalated: responseModel.escalated,
        );
        
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, TicketDetails>> getTicketDetails(int ticketId) async {
    if (await networkInfo.isConnected) {
      try {
        final responseModel = await remoteDataSource.getTicketDetails(ticketId);
        
        // Convert model to entity
        final details = TicketDetails(
          id: responseModel.id,
          subject: responseModel.subject,
          priority: responseModel.priority,
          assignee: responseModel.assignee,
          description: responseModel.description,
          ticketStatus: responseModel.ticketStatus,
          documents: responseModel.documents.map((doc) {
            return TicketDocument(
              id: doc.id,
              url: doc.url,
              name: doc.name,
            );
          }).toList(),
          activity: responseModel.activity.map((act) {
            return TicketActivity(
              action: act.action,
              actionType: act.actionType,
              userEmail: act.userEmail,
              firstName: act.firstName,
              lastName: act.lastName,
              createdBy: act.createdBy,
              createdAt: act.createdAt,
            );
          }).toList(),
          ticketCategoryId: responseModel.ticketCategoryId,
          ticketSubCategoryId: responseModel.ticketSubCategoryId,
          ticketID: responseModel.ticketID,
          raisedFor: responseModel.raisedFor != null
              ? TicketUser(
                  id: responseModel.raisedFor!.id,
                  firstName: responseModel.raisedFor!.firstName,
                  lastName: responseModel.raisedFor!.lastName,
                  profileColor: responseModel.raisedFor!.profileColor,
                  imageUrl: responseModel.raisedFor!.imageUrl,
                  phone: responseModel.raisedFor!.phone,
                  email: responseModel.raisedFor!.email,
                )
              : null,
          createdBy: responseModel.createdBy,
          createdAt: responseModel.createdAt,
          assigneeTicket: responseModel.assigneeTicket != null
              ? TicketUser(
                  id: responseModel.assigneeTicket!.id,
                  firstName: responseModel.assigneeTicket!.firstName,
                  lastName: responseModel.assigneeTicket!.lastName,
                  profileColor: responseModel.assigneeTicket!.profileColor,
                  imageUrl: responseModel.assigneeTicket!.imageUrl,
                  phone: responseModel.assigneeTicket!.phone,
                  email: responseModel.assigneeTicket!.email,
                )
              : null,
          createdByUser: responseModel.createdByUser != null
              ? TicketUser(
                  id: responseModel.createdByUser!.id,
                  firstName: responseModel.createdByUser!.firstName,
                  lastName: responseModel.createdByUser!.lastName,
                  profileColor: responseModel.createdByUser!.profileColor,
                  imageUrl: responseModel.createdByUser!.imageUrl,
                  phone: responseModel.createdByUser!.phone,
                  email: responseModel.createdByUser!.email,
                )
              : null,
          ticketCategory: responseModel.ticketCategory != null
              ? TicketCategory(
                  id: responseModel.ticketCategory!.id,
                  categoryName: responseModel.ticketCategory!.categoryName,
                  followers: responseModel.ticketCategory!.followers,
                  assignee: responseModel.ticketCategory!.assignee,
                  hasSubCategories: responseModel.ticketCategory!.hasSubCategories,
                )
              : null,
          ticketSubCategory: responseModel.ticketSubCategory,
          followers: responseModel.followers.map((follower) {
            return TicketFollower(
              id: follower.id,
              firstName: follower.firstName,
              lastName: follower.lastName,
              profileColor: follower.profileColor,
              imageUrl: follower.imageUrl,
            );
          }).toList(),
        );
        
        return Right(details);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, TicketStats>> uploadTicketFile(
    int clientId,
    int ticketId,
    String filePath,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final responseModel = await remoteDataSource.uploadTicketFile(
          clientId,
          ticketId,
          filePath,
        );

        final stats = TicketStats(
          open: responseModel.open,
          inProgress: responseModel.inProgress,
          resolved: responseModel.resolved,
          escalated: responseModel.escalated,
        );

        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }
}
