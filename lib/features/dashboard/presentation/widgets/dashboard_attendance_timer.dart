// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:dio/dio.dart';
// import '../../../../core/widgets/attendance_timer_circle.dart';
// import '../../../../core/utils/time_utils.dart';
// import '../../../../core/network/api_client.dart';
// import '../../../../core/network/network_info.dart';
// import '../../../attendance/data/datasources/attendance_details_remote_datasource.dart';
// import '../../../attendance/data/repositories/attendance_details_repository_impl.dart';
// import '../../../attendance/domain/usecases/get_attendance_details_usecase.dart';
// import '../../../attendance/domain/entities/attendance_details.dart';
// import '../../../../core/constants/app_colors.dart';
// import '../../../../core/constants/app_text_styles.dart';
// import '../../../../core/constants/app_strings.dart';
//
// /// Dashboard attendance timer widget
// class DashboardAttendanceTimer extends StatefulWidget {
//   const DashboardAttendanceTimer({super.key});
//
//   @override
//   State<DashboardAttendanceTimer> createState() => _DashboardAttendanceTimerState();
// }
//
// class _DashboardAttendanceTimerState extends State<DashboardAttendanceTimer> {
//   AttendanceDetails? _attendanceDetails;
//   bool _isLoading = true;
//   Timer? _updateTimer;
//   double _workedHours = 0.0;
//   double _shiftHours = 8.0; // Default shift hours
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAttendanceDetails();
//     // Update timer every second to refresh worked hours when punched in
//     _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       _updateWorkedHours();
//     });
//   }
//
//   @override
//   void dispose() {
//     _updateTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _loadAttendanceDetails() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final networkInfo = NetworkInfoImpl(Connectivity());
//       final dio = Dio();
//       final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
//       final remoteDataSource =
//           AttendanceDetailsRemoteDataSourceImpl(apiClient);
//       final repository = AttendanceDetailsRepositoryImpl(
//         remoteDataSource: remoteDataSource,
//         networkInfo: networkInfo,
//       );
//       final getAttendanceDetailsUseCase =
//           GetAttendanceDetailsUseCase(repository);
//
//       final result = await getAttendanceDetailsUseCase();
//
//       result.fold(
//         (failure) {
//           setState(() {
//             _isLoading = false;
//           });
//         },
//         (attendanceDetails) {
//           setState(() {
//             _attendanceDetails = attendanceDetails;
//             _isLoading = false;
//             _updateWorkedHours();
//           });
//         },
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _updateWorkedHours() {
//     if (!mounted) return;
//
//     setState(() {
//       _workedHours = TimeUtils.getWorkedHours(
//         totalTime: _attendanceDetails?.totalTime,
//         punchIn: _attendanceDetails?.punchIn,
//         punchOut: _attendanceDetails?.punchOut,
//         punchInIp: _attendanceDetails?.punchInIp,
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Container(
//       padding: EdgeInsets.all(screenWidth * 0.042), // ~4.2% of screen width
//       decoration: BoxDecoration(
//         color: AppColors.background,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.textPrimary.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             AppStrings.attendance,
//             style: AppTextStyles.heading4(context).copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: screenHeight * 0.02), // 2% of screen height
//           if (_isLoading)
//             const Center(
//               child: CircularProgressIndicator(),
//             )
//           else
//             Column(
//               children: [
//                 AttendanceTimerCircle(
//                   workedHours: _workedHours,
//                   shiftHours: _shiftHours,
//                   size: 120,
//                 ),
//                 SizedBox(height: screenHeight * 0.015), // 1.5% of screen height
//                 Text(
//                   '${_workedHours.toStringAsFixed(1)} / $_shiftHours hrs',
//                   style: AppTextStyles.bodyMedium(context).copyWith(
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
// }
