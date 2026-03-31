// import 'package:flutter/material.dart';
// import '../constants/app_strings.dart';
//
// /// Error display widget
// class ErrorDisplayWidget extends StatelessWidget {
//   final String message;
//   final VoidCallback? onRetry;
//
//   const ErrorDisplayWidget({
//     super.key,
//     required this.message,
//     this.onRetry,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 64,
//               color: Theme.of(context).colorScheme.error,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               AppStrings.error,
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             if (onRetry != null) ...[
//               const SizedBox(height: 24),
//               ElevatedButton.icon(
//                 onPressed: onRetry,
//                 icon: const Icon(Icons.refresh),
//                 label: Text(AppStrings.retry),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
//
