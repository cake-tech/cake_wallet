import 'dart:math';
import 'dart:ui';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart';
import 'package:fast_scanner/fast_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanPage extends StatefulWidget {
  ScanPage({super.key});

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

  @override
  void initState() {
    super.initState();
    controller.addListener(() => setState(() {
          _numCameras = controller.value.availableCameras;
        }));
  }

  @override
  Widget build(BuildContext context) {
    final double cutoutSize = MediaQuery.of(context).size.width * 0.8;
    const double cutoutRadius = 24.0;
    const Duration textModeSwitchDuration = Duration(milliseconds: 300);
    final buttonColor = _frontFlashMode ? Colors.black.withAlpha(40) : Colors.white.withAlpha(40);
    final buttonIconColor = _frontFlashMode ? Colors.black : Colors.white;

    return Material(
      child: Stack(
        children: [
          MobileScanner(
            controller: controller,
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _textInputMode = false;
              }),
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
                    : ClipPath(
                        key: ValueKey(0),
                        clipper: HoleClipper(
                          width: cutoutSize,
                          height: cutoutSize,
                          radius: cutoutRadius,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                          child: Container(
                            color: _frontFlashMode ? Colors.white : Colors.black.withAlpha(153),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _textInputMode ? 0 : 1,
            duration: textModeSwitchDuration,
            child: Center(
              child: Container(
                width: cutoutSize,
                height: cutoutSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4.0),
                  borderRadius: BorderRadius.circular(cutoutRadius),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                ModalTopBar(
                  title: "",
                  trailingWidget: Row(
                    spacing: 8,
                    children: [
                      if ((_numCameras ?? 0) > 1)
                        ModernButton.svg(
                          size: 36,
                          iconSize: 24,
                          svgPath: "assets/new-ui/camera_flip.svg",
                          onPressed: controller.switchCamera,
                          iconColor: buttonIconColor,
                          backgroundColor: buttonColor,
                        ),
                      ModernButton.svg(
                        size: 36,
                        iconSize: 20,
                        svgPath: "assets/new-ui/camera_flash.svg",
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
                  leadingWidget: Row(
                    textBaseline: TextBaseline.ideographic,
                    spacing: 24,
                    children: [
                      ModernButton(
                        size: 36,
                        iconSize: 18,
                        icon: Icon(Icons.arrow_back_ios_new),
                        onPressed: Navigator.of(context).pop,
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
                      child: TextField(
                        enabled: _textInputMode,
                        controller: textController,
                        focusNode: textFocusNode,
                        decoration: InputDecoration(hintText: S.of(context).enter_code),
                      ),
                    ),
                    FloatingIconButton(
                        iconPath: "assets/new-ui/paste.svg", onPressed: () async {
                          final data = await Clipboard.getData("text/plain");
                          if(data?.text != null) {
                            textController.text = data!.text!;
                          }
                    }),
                    SizedBox(width: 2,)
                  ],
                ),
              ),
            ),
          ),
          Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: textModeSwitchDuration,
                opacity: _textInputMode ? 0 : 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    ScanPageButton(
                        onTap: () {},
                        icon: Icons.photo_outlined,
                        label: S.of(context).gallery,
                        buttonColor: buttonColor,
                        buttonIconColor: buttonIconColor),
                    ScanPageButton(
                        onTap: () {
                          setState(() {
                            _textInputMode = true;
                          });
                          Future.delayed(textModeSwitchDuration)
                              .then((val) => textFocusNode.requestFocus());
                        },
                        icon: Icons.edit_outlined,
                        label: S.of(context).input,
                        buttonColor: buttonColor,
                        buttonIconColor: buttonIconColor),
                    ScanPageButton(
                        onTap: () {},
                        icon: Icons.question_mark,
                        buttonColor: buttonColor,
                        buttonIconColor: buttonIconColor)
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class ScanPageButton extends StatelessWidget {
  const ScanPageButton(
      {super.key,
      required this.onTap,
      required this.icon,
      this.label,
      required this.buttonColor,
      required this.buttonIconColor});

  final VoidCallback onTap;
  final IconData icon;
  final String? label;
  final Color buttonColor;
  final Color buttonIconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(99999)),
          child: Padding(
            padding: EdgeInsets.only(
                top: 10, bottom: 10, left: label == null ? 10 : 16, right: label == null ? 10 : 20),
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
        ));
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
