// import 'package:collectivWork/core/constants/app_colors.dart';
// import 'package:collectivWork/core/constants/app_text_styles.dart';
// import 'package:collectivWork/core/utils/app_spacing.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// import 'package:flutter/material.dart';
//
// class AppEmojiPickerSheet extends StatelessWidget {
//   final TextEditingController controller;
//   final ValueChanged<String>? onChanged;
//   final VoidCallback? onEmojiSelected;
//   final VoidCallback? onBackspacePressed;
//   final String title;
//   final String subtitle;
//   final bool useSafeArea;
//   final bool showHeader;
//   final bool showDragHandle;
//   final double maxHeightFactor;
//   final EdgeInsetsGeometry? padding;
//
//   const AppEmojiPickerSheet({
//     super.key,
//     required this.controller,
//     this.onChanged,
//     this.onEmojiSelected,
//     this.onBackspacePressed,
//     this.title = 'Choose an emoji',
//     this.subtitle = 'Tap an emoji to insert it into your text.',
//     this.useSafeArea = true,
//     this.showHeader = true,
//     this.showDragHandle = true,
//     this.maxHeightFactor = 0.58,
//     this.padding,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final maxSheetHeight =
//         MediaQuery.sizeOf(context).height * maxHeightFactor;
//
//     Widget content = ConstrainedBox(
//       constraints: BoxConstraints(maxHeight: maxSheetHeight),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           final reservedHeaderHeight =
//               showHeader ? (showDragHandle ? 108.0 : 88.0) : 0.0;
//           final pickerHeight = (constraints.maxHeight - reservedHeaderHeight)
//               .clamp(220.0, 320.0);
//
//           return Padding(
//             padding:
//                 padding ??
//                 const EdgeInsets.fromLTRB(
//                   AppSpacing.lg,
//                   AppSpacing.md,
//                   AppSpacing.lg,
//                   AppSpacing.lg,
//                 ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (showDragHandle) ...[
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFD5DAE1),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                     ),
//                   ),
//                   AppSpacing.vLg,
//                 ],
//                 if (showHeader) ...[
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               title,
//                               style: AppTextStyles.heading5(
//                                 context,
//                               ).copyWith(fontWeight: FontWeight.w700),
//                             ),
//                             AppSpacing.vXs,
//                             Text(
//                               subtitle,
//                               style: AppTextStyles.bodySmall(
//                                 context,
//                               ).copyWith(color: AppColors.textSecondary),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         tooltip: 'Delete last',
//                         onPressed: onBackspacePressed,
//                         icon: const Icon(
//                           Icons.backspace_outlined,
//                           color: AppColors.attendanceTeal,
//                         ),
//                       ),
//                     ],
//                   ),
//                   AppSpacing.vLg,
//                 ],
//                 SizedBox(
//                   height: pickerHeight.toDouble(),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(20),
//                     child: EmojiPicker(
//                       textEditingController: controller,
//                       onEmojiSelected: (_, __) {
//                         onChanged?.call(controller.text);
//                         onEmojiSelected?.call();
//                       },
//                       onBackspacePressed: () {
//                         onChanged?.call(controller.text);
//                         onBackspacePressed?.call();
//                       },
//                       config: Config(
//                         height: pickerHeight.toDouble(),
//                         checkPlatformCompatibility: true,
//                         customSearchIcon: const Icon(
//                           Icons.search,
//                           color: Color(0xFF98A2B3),
//                         ),
//                         customBackspaceIcon: const Icon(
//                           Icons.backspace_outlined,
//                           color: AppColors.attendanceTeal,
//                         ),
//                         emojiViewConfig: const EmojiViewConfig(
//                           backgroundColor: Colors.white,
//                           columns: 8,
//                           emojiSizeMax: 30,
//                         ),
//                         skinToneConfig: const SkinToneConfig(),
//                         categoryViewConfig: const CategoryViewConfig(
//                           initCategory: Category.SMILEYS,
//                           backgroundColor: Color(0xFFF7F9FC),
//                           indicatorColor: AppColors.attendanceTeal,
//                           iconColor: Color(0xFF98A2B3),
//                           iconColorSelected: AppColors.attendanceTeal,
//                           backspaceColor: AppColors.attendanceTeal,
//                         ),
//                         bottomActionBarConfig: const BottomActionBarConfig(
//                           enabled: false,
//                         ),
//                         searchViewConfig: const SearchViewConfig(
//                           backgroundColor: Colors.white,
//                           buttonIconColor: AppColors.attendanceTeal,
//                         ),
//                         viewOrderConfig: const ViewOrderConfig(
//                           top: EmojiPickerItem.categoryBar,
//                           middle: EmojiPickerItem.emojiView,
//                           bottom: EmojiPickerItem.searchBar,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//
//     if (useSafeArea) {
//       content = SafeArea(top: false, child: content);
//     }
//
//     return content;
//   }
// }
