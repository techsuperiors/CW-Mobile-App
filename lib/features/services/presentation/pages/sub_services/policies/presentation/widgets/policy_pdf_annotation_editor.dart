import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/app_spacing.dart';

enum PolicyPdfAnnotationType { text, signature }

enum PolicyPdfPlacementMode { none, text, signature }

class PolicyPdfAnnotation {
  final String id;
  final PolicyPdfAnnotationType type;
  final int pageIndex;
  final double xRatio;
  final double yRatio;
  final double widthRatio;
  final double heightRatio;
  final String? text;
  final double fontScale;
  final Uint8List? signatureBytes;

  const PolicyPdfAnnotation({
    required this.id,
    required this.type,
    required this.pageIndex,
    required this.xRatio,
    required this.yRatio,
    required this.widthRatio,
    required this.heightRatio,
    this.text,
    this.fontScale = 0.030,
    this.signatureBytes,
  });

  bool get isText => type == PolicyPdfAnnotationType.text;

  bool get isSignature => type == PolicyPdfAnnotationType.signature;

  PolicyPdfAnnotation copyWith({
    String? id,
    PolicyPdfAnnotationType? type,
    int? pageIndex,
    double? xRatio,
    double? yRatio,
    double? widthRatio,
    double? heightRatio,
    String? text,
    double? fontScale,
    Uint8List? signatureBytes,
    bool clearSignatureBytes = false,
  }) {
    return PolicyPdfAnnotation(
      id: id ?? this.id,
      type: type ?? this.type,
      pageIndex: pageIndex ?? this.pageIndex,
      xRatio: xRatio ?? this.xRatio,
      yRatio: yRatio ?? this.yRatio,
      widthRatio: widthRatio ?? this.widthRatio,
      heightRatio: heightRatio ?? this.heightRatio,
      text: text ?? this.text,
      fontScale: fontScale ?? this.fontScale,
      signatureBytes:
          clearSignatureBytes ? null : (signatureBytes ?? this.signatureBytes),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'pageIndex': pageIndex,
      'xRatio': xRatio,
      'yRatio': yRatio,
      'widthRatio': widthRatio,
      'heightRatio': heightRatio,
      'text': text,
      'fontScale': fontScale,
      'signatureBytes':
          signatureBytes == null ? null : base64Encode(signatureBytes!),
    };
  }

  factory PolicyPdfAnnotation.fromJson(Map<String, dynamic> json) {
    final typeName = (json['type'] as String? ?? '').toLowerCase();
    final signatureBase64 = json['signatureBytes'] as String?;

    return PolicyPdfAnnotation(
      id: json['id'] as String? ?? UniqueKey().toString(),
      type:
          typeName == PolicyPdfAnnotationType.signature.name
              ? PolicyPdfAnnotationType.signature
              : PolicyPdfAnnotationType.text,
      pageIndex: _toInt(json['pageIndex']),
      xRatio: _toDouble(json['xRatio'], fallback: 0.10),
      yRatio: _toDouble(json['yRatio'], fallback: 0.10),
      widthRatio: _toDouble(json['widthRatio'], fallback: 0.28),
      heightRatio: _toDouble(json['heightRatio'], fallback: 0.10),
      text: json['text'] as String?,
      fontScale: _toDouble(json['fontScale'], fallback: 0.030),
      signatureBytes:
          signatureBase64 == null || signatureBase64.isEmpty
              ? null
              : base64Decode(signatureBase64),
    );
  }

  static double _toDouble(dynamic value, {required double fallback}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class PolicyPdfEditorController extends ChangeNotifier {
  List<PolicyPdfAnnotation> _annotations = <PolicyPdfAnnotation>[];
  String? _selectedAnnotationId;
  PolicyPdfPlacementMode _placementMode = PolicyPdfPlacementMode.none;
  Uint8List? _pendingSignatureBytes;

  List<PolicyPdfAnnotation> get annotations =>
      List<PolicyPdfAnnotation>.unmodifiable(_annotations);

  String? get selectedAnnotationId => _selectedAnnotationId;

  PolicyPdfPlacementMode get placementMode => _placementMode;

  bool get isAwaitingPlacement => _placementMode != PolicyPdfPlacementMode.none;

  bool get hasAnnotations => _annotations.isNotEmpty;

  bool get hasSelectedAnnotation => _selectedAnnotationId != null;

  bool get hasSignatureAnnotations =>
      _annotations.any((annotation) => annotation.isSignature);

  String? get placementMessage {
    switch (_placementMode) {
      case PolicyPdfPlacementMode.text:
        return 'Tap anywhere on the PDF to place text.';
      case PolicyPdfPlacementMode.signature:
        return 'Tap anywhere on the PDF to place the signature.';
      case PolicyPdfPlacementMode.none:
        return null;
    }
  }

  void setAnnotations(List<PolicyPdfAnnotation> annotations) {
    _annotations = List<PolicyPdfAnnotation>.from(annotations);
    _selectedAnnotationId = null;
    _placementMode = PolicyPdfPlacementMode.none;
    _pendingSignatureBytes = null;
    notifyListeners();
  }

  void startTextPlacement() {
    _selectedAnnotationId = null;
    _pendingSignatureBytes = null;
    _placementMode = PolicyPdfPlacementMode.text;
    notifyListeners();
  }

  void startSignaturePlacement(Uint8List signatureBytes) {
    _selectedAnnotationId = null;
    _pendingSignatureBytes = signatureBytes;
    _placementMode = PolicyPdfPlacementMode.signature;
    notifyListeners();
  }

  void addSignatureAnnotation({
    required Uint8List signatureBytes,
    int pageIndex = 0,
  }) {
    const widthRatio = 0.28;
    const heightRatio = 0.12;
    final annotation = PolicyPdfAnnotation(
      id: UniqueKey().toString(),
      type: PolicyPdfAnnotationType.signature,
      pageIndex: pageIndex,
      xRatio: (0.5 - (widthRatio / 2)).clamp(0.0, 1 - widthRatio),
      yRatio: 0.16,
      widthRatio: widthRatio,
      heightRatio: heightRatio,
      signatureBytes: signatureBytes,
    );

    _annotations = <PolicyPdfAnnotation>[..._annotations, annotation];
    _selectedAnnotationId = annotation.id;
    _placementMode = PolicyPdfPlacementMode.none;
    _pendingSignatureBytes = null;
    notifyListeners();
  }

  void cancelPlacement() {
    if (_placementMode == PolicyPdfPlacementMode.none &&
        _pendingSignatureBytes == null) {
      return;
    }

    _placementMode = PolicyPdfPlacementMode.none;
    _pendingSignatureBytes = null;
    notifyListeners();
  }

  void selectAnnotation(String? annotationId) {
    if (_selectedAnnotationId == annotationId &&
        _placementMode == PolicyPdfPlacementMode.none) {
      return;
    }

    _selectedAnnotationId = annotationId;
    _placementMode = PolicyPdfPlacementMode.none;
    _pendingSignatureBytes = null;
    notifyListeners();
  }

  void deleteSelectedAnnotation() {
    if (_selectedAnnotationId == null) return;

    _annotations =
        _annotations
            .where((annotation) => annotation.id != _selectedAnnotationId)
            .toList();
    _selectedAnnotationId = null;
    notifyListeners();
  }

  void placeTextAnnotation({
    required int pageIndex,
    required Offset tapPosition,
    required Size pageSize,
    required String text,
  }) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      cancelPlacement();
      return;
    }

    const widthRatio = 0.42;
    const heightRatio = 0.08;
    final annotation = PolicyPdfAnnotation(
      id: UniqueKey().toString(),
      type: PolicyPdfAnnotationType.text,
      pageIndex: pageIndex,
      xRatio: _clampPosition(
        (tapPosition.dx / pageSize.width) - (widthRatio / 2),
        maxValue: 1 - widthRatio,
      ),
      yRatio: _clampPosition(
        (tapPosition.dy / pageSize.height) - (heightRatio / 2),
        maxValue: 1 - heightRatio,
      ),
      widthRatio: widthRatio,
      heightRatio: heightRatio,
      text: trimmedText,
      fontScale: 0.028,
    );

    _annotations = <PolicyPdfAnnotation>[..._annotations, annotation];
    _selectedAnnotationId = annotation.id;
    _placementMode = PolicyPdfPlacementMode.none;
    _pendingSignatureBytes = null;
    notifyListeners();
  }

  void placeSignatureAnnotation({
    required int pageIndex,
    required Offset tapPosition,
    required Size pageSize,
  }) {
    final signatureBytes = _pendingSignatureBytes;
    if (signatureBytes == null) {
      cancelPlacement();
      return;
    }

    const widthRatio = 0.28;
    const heightRatio = 0.12;
    final annotation = PolicyPdfAnnotation(
      id: UniqueKey().toString(),
      type: PolicyPdfAnnotationType.signature,
      pageIndex: pageIndex,
      xRatio: _clampPosition(
        (tapPosition.dx / pageSize.width) - (widthRatio / 2),
        maxValue: 1 - widthRatio,
      ),
      yRatio: _clampPosition(
        (tapPosition.dy / pageSize.height) - (heightRatio / 2),
        maxValue: 1 - heightRatio,
      ),
      widthRatio: widthRatio,
      heightRatio: heightRatio,
      signatureBytes: signatureBytes,
    );

    _annotations = <PolicyPdfAnnotation>[..._annotations, annotation];
    _selectedAnnotationId = annotation.id;
    _placementMode = PolicyPdfPlacementMode.none;
    _pendingSignatureBytes = null;
    notifyListeners();
  }

  void updateAnnotationPosition({
    required String annotationId,
    required double deltaXRatio,
    required double deltaYRatio,
  }) {
    final annotationIndex = _annotations.indexWhere(
      (annotation) => annotation.id == annotationId,
    );
    if (annotationIndex == -1) return;

    final annotation = _annotations[annotationIndex];
    _annotations[annotationIndex] = annotation.copyWith(
      xRatio: _clampPosition(
        annotation.xRatio + deltaXRatio,
        maxValue: 1 - annotation.widthRatio,
      ),
      yRatio: _clampPosition(
        annotation.yRatio + deltaYRatio,
        maxValue: 1 - annotation.heightRatio,
      ),
    );
    notifyListeners();
  }

  void resizeSignature({
    required String annotationId,
    required double deltaWidthRatio,
  }) {
    final annotationIndex = _annotations.indexWhere(
      (annotation) => annotation.id == annotationId,
    );
    if (annotationIndex == -1) return;

    final annotation = _annotations[annotationIndex];
    if (!annotation.isSignature) return;

    final aspectRatio = annotation.widthRatio / annotation.heightRatio;
    final newWidth = (annotation.widthRatio + deltaWidthRatio).clamp(0.12, 0.55);
    final newHeight = (newWidth / aspectRatio).clamp(0.05, 0.30);

    _annotations[annotationIndex] = annotation.copyWith(
      widthRatio: newWidth,
      heightRatio: newHeight,
      xRatio: _clampPosition(annotation.xRatio, maxValue: 1 - newWidth),
      yRatio: _clampPosition(annotation.yRatio, maxValue: 1 - newHeight),
    );
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedAnnotationId == null) return;
    _selectedAnnotationId = null;
    notifyListeners();
  }

  double _clampPosition(double value, {required double maxValue}) {
    return value.clamp(0.0, maxValue.clamp(0.0, 1.0));
  }
}

class PolicyPdfAnnotationEditor extends StatefulWidget {
  final String? sourcePdfUrl;
  final String? sourcePdfFilePath;
  final PolicyPdfEditorController controller;
  final bool readOnly;

  const PolicyPdfAnnotationEditor({
    super.key,
    this.sourcePdfUrl,
    this.sourcePdfFilePath,
    required this.controller,
    this.readOnly = false,
  }) : assert(
         sourcePdfUrl != null || sourcePdfFilePath != null,
         'Either sourcePdfUrl or sourcePdfFilePath must be provided.',
       );

  @override
  State<PolicyPdfAnnotationEditor> createState() =>
      _PolicyPdfAnnotationEditorState();
}

class _PolicyPdfAnnotationEditorState extends State<PolicyPdfAnnotationEditor> {
  static final Map<String, List<_RenderedPdfPage>> _pageCache =
      <String, List<_RenderedPdfPage>>{};

  bool _isPreparingPages = true;
  String? _renderError;
  List<_RenderedPdfPage> _pages = const <_RenderedPdfPage>[];

  @override
  void initState() {
    super.initState();
    _preparePages();
  }

  @override
  void didUpdateWidget(covariant PolicyPdfAnnotationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_cacheKey(oldWidget) != _cacheKey(widget)) {
      _preparePages();
    }
  }

  Future<void> _preparePages() async {
    final cacheKey = _cacheKey(widget);
    final cachedPages = _pageCache[cacheKey];
    if (cachedPages != null && cachedPages.isNotEmpty) {
      setState(() {
        _pages = cachedPages;
        _renderError = null;
        _isPreparingPages = false;
      });
      return;
    }

    setState(() {
      _isPreparingPages = true;
      _renderError = null;
      _pages = const <_RenderedPdfPage>[];
    });

    try {
      final sourcePdfBytes = await _loadSourcePdfBytes();
      if (sourcePdfBytes.isEmpty) {
        throw Exception('Unable to load the source policy PDF.');
      }

      final rasterPages = Printing.raster(sourcePdfBytes, dpi: 110);
      final renderedPages = <_RenderedPdfPage>[];

      await for (final page in rasterPages) {
        renderedPages.add(
          _RenderedPdfPage(
            imageBytes: await page.toPng(),
            width: page.width.toDouble(),
            height: page.height.toDouble(),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _pages = renderedPages;
        _isPreparingPages = false;
      });
      _pageCache[cacheKey] = List<_RenderedPdfPage>.unmodifiable(
        renderedPages,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _renderError = error.toString();
        _isPreparingPages = false;
      });
    }
  }

  Future<Uint8List> _loadSourcePdfBytes() async {
    final sourcePdfFilePath = widget.sourcePdfFilePath?.trim() ?? '';
    if (sourcePdfFilePath.isNotEmpty) {
      final file = File(sourcePdfFilePath);
      if (!await file.exists()) {
        throw Exception('Unable to load the source policy PDF.');
      }

      return file.readAsBytes();
    }

    final response = await Dio().get<List<int>>(
      widget.sourcePdfUrl!,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data ?? const <int>[]);
  }

  String _cacheKey(PolicyPdfAnnotationEditor widget) {
    final filePath = widget.sourcePdfFilePath?.trim() ?? '';
    if (filePath.isNotEmpty) {
      return 'file:$filePath';
    }
    return 'url:${widget.sourcePdfUrl!.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreparingPages) {
      return _buildStatusCard(
        context,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_renderError != null) {
      return _buildStatusCard(
        context,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Text(
            _renderError!,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pageChildren = <Widget>[
              for (var index = 0; index < _pages.length; index++) ...[
                if (index > 0) AppSpacing.vLg,
                _buildPage(context, pageIndex: index, page: _pages[index]),
              ],
            ];

            if (constraints.hasBoundedHeight) {
              return ListView(
                padding: EdgeInsets.zero,
                children: pageChildren,
              );
            }

            return Column(children: pageChildren);
          },
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required int pageIndex,
    required _RenderedPdfPage page,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Page ${pageIndex + 1}',
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.vSm,
        LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth;
            final pageHeight = pageWidth * (page.height / page.width);
            final pageSize = Size(pageWidth, pageHeight);
            final pageAnnotations =
                widget.controller.annotations
                    .where((annotation) => annotation.pageIndex == pageIndex)
                    .toList();

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown:
                  widget.readOnly || !widget.controller.isAwaitingPlacement
                      ? null
                      : (details) => _handlePageTap(
                        pageIndex: pageIndex,
                        localPosition: details.localPosition,
                        pageSize: pageSize,
                      ),
              onTap:
                  widget.readOnly || widget.controller.isAwaitingPlacement
                      ? null
                      : widget.controller.clearSelection,
              child: Container(
                width: pageWidth,
                height: pageHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.memory(page.imageBytes, fit: BoxFit.fill),
                      ),
                      for (final annotation in pageAnnotations)
                        _buildAnnotation(
                          context,
                          annotation: annotation,
                          pageSize: pageSize,
                        ),
                      if (widget.controller.isAwaitingPlacement && !widget.readOnly)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: AppColors.primary.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnotation(
    BuildContext context, {
    required PolicyPdfAnnotation annotation,
    required Size pageSize,
  }) {
    final left = annotation.xRatio * pageSize.width;
    final top = annotation.yRatio * pageSize.height;
    final width = annotation.widthRatio * pageSize.width;
    final height = annotation.heightRatio * pageSize.height;
    final isSelected = widget.controller.selectedAnnotationId == annotation.id;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap:
                widget.readOnly
                    ? null
                    : () => widget.controller.selectAnnotation(annotation.id),
            onPanStart:
                widget.readOnly
                    ? null
                    : (_) => widget.controller.selectAnnotation(annotation.id),
            onPanUpdate:
                widget.readOnly
                    ? null
                    : (details) => widget.controller.updateAnnotationPosition(
                      annotationId: annotation.id,
                      deltaXRatio: details.delta.dx / pageSize.width,
                      deltaYRatio: details.delta.dy / pageSize.height,
                    ),
            child: annotation.isSignature
                ? Container(
                    decoration: BoxDecoration(
                      border:
                          isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.memory(
                      annotation.signatureBytes!,
                      fit: BoxFit.contain,
                    ),
                  )
                : Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      annotation.text ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: pageSize.width * annotation.fontScale,
                        height: 1.1,
                      ),
                    ),
                  ),
          ),
          if (!widget.readOnly && isSelected && annotation.isSignature)
            Positioned(
              right: -10,
              bottom: -10,
              child: GestureDetector(
                onPanUpdate:
                    (details) => widget.controller.resizeSignature(
                      annotationId: annotation.id,
                      deltaWidthRatio:
                          (details.delta.dx / pageSize.width) +
                          (details.delta.dy / pageSize.height),
                    ),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handlePageTap({
    required int pageIndex,
    required Offset localPosition,
    required Size pageSize,
  }) async {
    if (widget.controller.placementMode == PolicyPdfPlacementMode.signature) {
      widget.controller.placeSignatureAnnotation(
        pageIndex: pageIndex,
        tapPosition: localPosition,
        pageSize: pageSize,
      );
      return;
    }

    if (widget.controller.placementMode == PolicyPdfPlacementMode.text) {
      final text = await _showTextInputDialog(context);
      if (!mounted) return;

      await Future<void>.delayed(const Duration(milliseconds: 24));
      if (!mounted) return;

      if (text == null || text.trim().isEmpty) {
        widget.controller.cancelPlacement();
        return;
      }

      widget.controller.placeTextAnnotation(
        pageIndex: pageIndex,
        tapPosition: localPosition,
        pageSize: pageSize,
        text: text,
      );
    }
  }

  Future<String?> _showTextInputDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _PolicyAddTextDialog(),
    );
  }

  Widget _buildStatusCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _RenderedPdfPage {
  final Uint8List imageBytes;
  final double width;
  final double height;

  const _RenderedPdfPage({
    required this.imageBytes,
    required this.width,
    required this.height,
  });
}

class _PolicyAddTextDialog extends StatefulWidget {
  const _PolicyAddTextDialog();

  @override
  State<_PolicyAddTextDialog> createState() => _PolicyAddTextDialogState();
}

class _PolicyAddTextDialogState extends State<_PolicyAddTextDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_textController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth=MediaQuery.of(context).size.width;
    final screenHeight=MediaQuery.of(context).size.height;
    return AlertDialog(
      title: const Text('Add Text'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter text to place on the PDF...',
          hintStyle: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.032,
            vertical: screenHeight * 0.015,
          ),
        ),
        maxLines: 3,
        style: AppTextStyles.bodyMedium(context),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
