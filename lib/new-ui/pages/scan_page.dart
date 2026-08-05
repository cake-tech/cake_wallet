import 'dart:math';
import 'dart:ui';

import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/scan_page/network_list.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:fast_scanner/fast_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:ur/ur_decoder.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.showHelp = false, this.showManualInput = true});

  final bool showHelp;
  final bool showManualInput;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController controller = MobileScannerController();
  int? _numCameras;
  bool _frontFlashMode = false;
  bool _textInputMode = false;
  final TextEditingController textController = TextEditingController();
  final FocusNode textFocusNode = FocusNode();
  List<String> urCodes = [];
  late var ur = URQRToURQRData(urCodes);
  final decoder = URDecoder();
  bool popped = false;
  Barcode? _barcode;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (mounted) {
        setState(() {
          _numCameras = controller.value.availableCameras;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    textController.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cutoutSize = MediaQuery.of(context).size.width * 0.8;
    const double cutoutRadius = 24.0;
    const Duration textModeSwitchDuration = Duration(milliseconds: 300);
    final buttonColor = _frontFlashMode ? Colors.black.withAlpha(40) : Colors.white.withAlpha(40);
    final buttonIconColor = _frontFlashMode ? Colors.black : Colors.white;
    final isScanningURQR = decoder.processedPartsCount() > 0;
    final double targetRadius = isScanningURQR ? (cutoutSize / 2) : cutoutRadius;

    return Material(
      child: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          // A full screen tap target would otherwise show up as one giant unlabeled
          // node; leaving text mode is also possible with the back button.
          Positioned.fill(
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: () => setState(() {
                  _textInputMode = false;
                }),
                child: RepaintBoundary(
                  child: AnimatedSwitcher(
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInQuad,
                    duration: textModeSwitchDuration,
                    child: _textInputMode
                        ? BackdropFilter(
                            key: ValueKey(1),
                            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                            child: Container(
                              color: _frontFlashMode ? Colors.white : Colors.black.withAlpha(153),
                            ),
                          )
                        : TweenAnimationBuilder<double>(
                            key: const ValueKey(0),
                            tween: Tween<double>(begin: 0.0, end: targetRadius),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                              child: Container(
                                color: _frontFlashMode ? Colors.white : Colors.black.withAlpha(153),
                              ),
                            ),
                            builder: (context, radius, child) {
                              return ClipPath(
                                clipper: HoleClipper(
                                  width: cutoutSize,
                                  height: cutoutSize,
                                  radius: radius,
                                ),
                                child: child,
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _textInputMode || isScanningURQR ? 0 : 1,
            duration: textModeSwitchDuration,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: targetRadius),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, radius, child) => Center(
                child: Container(
                  width: cutoutSize,
                  height: cutoutSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4.0),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                ModalTopBar(
                  title: "",
                  trailingWidget: AnimatedOpacity(
                    duration: textModeSwitchDuration,
                    opacity: _textInputMode ? 0 : 1,
                    child: Row(
                      spacing: 8,
                      children: [
                        if ((_numCameras ?? 0) > 1)
                          ModernButton.svg(
                            size: 36,
                            iconSize: 24,
                            svgPath: "assets/new-ui/camera_flip.svg",
                            onPressed: () {
                              controller.switchCamera();
                              setState(() {
                                _frontFlashMode = false;
                              });
                            },
                            iconColor: buttonIconColor,
                            backgroundColor: buttonColor,
                            semanticLabel: S.of(context).switch_camera,
                          ),
                        ModernButton(
                          size: 36,
                          iconSize: 24,
                          icon: Icon(
                              (controller.value.torchState == TorchState.on || _frontFlashMode)
                                  ? Icons.flash_off_outlined
                                  : Icons.flash_on),
                          semanticLabel:
                              (controller.value.torchState == TorchState.on || _frontFlashMode)
                                  ? S.of(context).turn_flash_off
                                  : S.of(context).turn_flash_on,
                          onPressed: () {
                            if (controller.value.cameraDirection == CameraFacing.front) {
                              setState(() {
                                _frontFlashMode = !_frontFlashMode;
                              });
                            } else {
                              controller.toggleTorch();
                            }
                          },
                          iconColor: buttonIconColor,
                          backgroundColor: buttonColor,
                        ),
                      ],
                    ),
                  ),
                  leadingWidget: Row(
                    textBaseline: TextBaseline.ideographic,
                    spacing: 24,
                    children: [
                      ModernButton(
                        size: 36,
                        iconSize: 18,
                        icon: Icon(Icons.arrow_back_ios_new),
                        semanticLabel: S.of(context).seed_alert_back,
                        onPressed: () {
                          if (_textInputMode) {
                            setState(() {
                              _textInputMode = false;
                            });
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        iconColor: buttonIconColor,
                        backgroundColor: buttonColor,
                      ),
                      Text(
                        S.of(context).scan,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600, color: buttonIconColor),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 18 +
                max(MediaQuery.of(context).viewInsets.bottom,
                    MediaQuery.of(context).viewPadding.bottom),
            left: 16,
            right: 16,
            child: RepaintBoundary(
              child: AnimatedOpacity(
                opacity: _textInputMode ? 1 : 0,
                duration: textModeSwitchDuration,
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: MergeSemantics(
                          child: Semantics(
                            label: S.of(context).enter_code,
                            child: TextField(
                              enabled: _textInputMode,
                              controller: textController,
                              focusNode: textFocusNode,
                              onSubmitted: (val) {
                                if (val.isNotEmpty) {
                                  Navigator.of(context).pop(val);
                                } else {
                                  setState(() {
                                    _textInputMode = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(hintText: S.of(context).enter_code),
                            ),
                          ),
                        ),
                      ),
                      FloatingIconButton(
                          iconPath: "assets/new-ui/paste.svg",
                          onPressed: () async {
                            final data = await Clipboard.getData("text/plain");
                            if (data?.text != null) {
                              textController.text = data!.text!;
                            }
                          }),
                      SizedBox(
                        width: 2,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                child: AnimatedOpacity(
                  duration: textModeSwitchDuration,
                  opacity: _textInputMode ? 0 : 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      // "not mvp"
                      // ScanPageButton(
                      //     onTap: () async {
                      //       FilePickerResult? res = await FilePicker.platform.pickFiles(
                      //         type: FileType.image,
                      //         allowMultiple: false,
                      //         withData: false,
                      //       );
                      //
                      //       if (res != null && res.paths.isNotEmpty && res.paths.first != null) {
                      //         final capture = await controller.analyzeImage(res.paths.first!);
                      //         if (capture != null) {
                      //           _handleBarcode(capture);
                      //         }
                      //       }
                      //     },
                      //     icon: Icons.photo_outlined,
                      //     label: S.of(context).gallery,
                      //     buttonColor: buttonColor,
                      //     buttonIconColor: buttonIconColor),
                      if (widget.showManualInput)
                        ScanPageButton(
                            onTap: () {
                              setState(() {
                                _textInputMode = true;
                              });
                              Future.delayed(textModeSwitchDuration)
                                  .then((val) => textFocusNode.requestFocus());
                            },
                            icon: Icons.edit_outlined,
                            label: S.of(context).manual_input,
                            buttonColor: buttonColor,
                            buttonIconColor: buttonIconColor),
                      if (widget.showHelp)
                        ScanPageButton(
                            onTap: () async {
                              if (_textInputMode) return;
                              try {
                                controller.stop();
                                await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    builder: (context) => ScanPageNetworkList());
                              } finally {
                                controller.start();
                              }
                            },
                            icon: Icons.question_mark,
                            semanticsLabel: S.of(context).help,
                            buttonColor: buttonColor,
                            buttonIconColor: buttonIconColor)
                    ],
                  ),
                ),
              )),
          AnimatedOpacity(
            duration: Duration(milliseconds: 500),
            opacity: isScanningURQR ? 1 : 0,
            child: Center(
              child: SegmentedCircularProgress(
                  progress: URQrProgress(
                    expectedPartCount: decoder.expectedPartCount() ?? 0,
                    processedPartsCount: decoder.processedPartsCount(),
                    receivedPartIndexes: decoder.receivedPartIndexes().toList(),
                    percentage: decoder.estimatedPercentComplete(),
                  ),
                  size: cutoutSize + 20,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.white.withAlpha(102)),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: isScanningURQR ? 1 : 0,
                // Three separate digits mean nothing on their own: announce the progress
                // as one node, and only while a multi part code is actually being scanned.
                child: ExcludeSemantics(
                  excluding: !isScanningURQR,
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label: S.of(context).qr_parts_scanned(
                        "${decoder.processedPartsCount()}", "${decoder.expectedPartCount() ?? 0}"),
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${decoder.processedPartsCount()}",
                          style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        Text(
                          "/",
                          style: TextStyle(
                              fontSize: 45, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          "${decoder.expectedPartCount()}",
                          style: TextStyle(
                              fontSize: 45, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    try {
      _handleBarcodeInternal(barcodes);
    } catch (e, st) {
      showPopUp<void>(
        context: context,
        builder: (context) {
          return AlertWithOneAction(
            alertTitle: S.of(context).error,
            alertContent: S.of(context).error_dialog_content,
            buttonText: S.of(context).ok,
            buttonAction: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
      printV("$e\n$st");
    }
  }

  void _handleBarcodeInternal(BarcodeCapture barcodes) {
    for (final barcode in barcodes.barcodes) {
      if (barcode.rawValue?.trim().isEmpty ?? false == false) continue;
      if (barcode.rawValue!.startsWith("ur:")) {
        if (urCodes.contains(barcode.rawValue)) continue;
        decoder.receivePart(barcode.rawValue!);
        setState(() {
          urCodes.add(barcode.rawValue!);
          ur = URQRToURQRData(urCodes);
        });
        if (decoder.estimatedPercentComplete() == 1) {
          setState(() {
            popped = true;
          });
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop(ur.inputs.join("\n"));
          });
        }
        ;
      }
    }
    if (urCodes.isNotEmpty) return;
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
      if (_barcode != null && popped != true) {
        setState(() {
          popped = true;
        });
        Navigator.of(context).pop(_barcode!.rawValue ?? _barcode!.rawBytes);
      }
    }
  }
}

class ScanPageButton extends StatelessWidget {
  const ScanPageButton(
      {super.key,
      required this.onTap,
      required this.icon,
      this.label,
      this.semanticsLabel,
      required this.buttonColor,
      required this.buttonIconColor});

  final VoidCallback onTap;
  final IconData icon;
  final String? label;

  /// Name for the icon-only variant, which has no visible [label].
  final String? semanticsLabel;
  final Color buttonColor;
  final Color buttonIconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
        button: true,
        enabled: true,
        label: semanticsLabel ?? label,
        onTap: onTap,
        excludeSemantics: true,
        child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration:
                  BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(99999)),
              child: Padding(
                padding: EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    left: label == null ? 10 : 16,
                    right: label == null ? 10 : 20),
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(icon, size: 28, color: buttonIconColor),
                    if (label != null)
                      Text(label!,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500, color: buttonIconColor))
                  ],
                ),
              ),
            )));
  }
}

class HoleClipper extends CustomClipper<Path> {
  final double width;
  final double height;
  final double radius;

  HoleClipper({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final Path fullScreenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: width,
            height: height,
          ),
          Radius.circular(radius),
        ),
      );

    return Path.combine(
      PathOperation.difference,
      fullScreenPath,
      cutoutPath,
    );
  }

  @override
  bool shouldReclip(covariant HoleClipper oldClipper) {
    return oldClipper.width != width || oldClipper.height != height || oldClipper.radius != radius;
  }
}

class SegmentedCircularProgress extends StatelessWidget {
  final URQrProgress progress;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const SegmentedCircularProgress({
    Key? key,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SegmentedCirclePainter(
        progress: progress,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      ),
    );
  }
}

class _SegmentedCirclePainter extends CustomPainter {
  final URQrProgress progress;
  static const double strokeWidth = 10;
  static const double gapAngle = 0.08;
  final Color activeColor;
  final Color inactiveColor;

  _SegmentedCirclePainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final totalSegments = progress.expectedPartCount;

    final sweepAngle = (2 * pi - (gapAngle * totalSegments)) / totalSegments;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2 + (gapAngle / 2);

    for (int i = 0; i < totalSegments; i++) {
      bool isHighlighted = progress.receivedPartIndexes.contains(i);

      paint.color = isHighlighted ? activeColor : inactiveColor;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedCirclePainter oldDelegate) {
    return !oldDelegate.progress.equals(progress) ||
        oldDelegate.progress.expectedPartCount != progress.expectedPartCount;
  }
}
