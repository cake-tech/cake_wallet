import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen() : super();

  @override
  ScanScreenState createState() => ScanScreenState();
}

class ScanScreenState extends State<ScanScreen> {
  MobileScannerController cameraController = MobileScannerController();

  bool popped = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> scanImage() async {
    // final ImagePicker imagePicker = ImagePicker();
    // final XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);
    // if (file?.path != null) {
    //   final bool qrCodeFound = await cameraController.analyzeImage(file!.path);
    //   if (!qrCodeFound && mounted && !popped) {
    //     UIUtil.showSnackbar(Z.of(context).qrUnknownError, context);
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          MobileScanner(
            controller: cameraController,
            onDetect: (BarcodeCapture barcodeCapture) {
              if (barcodeCapture.barcodes.isEmpty) return;
              final Barcode barcode = barcodeCapture.barcodes.first;
              if (barcode.rawValue == null) {
                debugPrint("Failed to scan Barcode");
                return;
              }
              final String? code = barcode.rawValue;
              // don't pop for null or empty strings:
              if (code == null || code.isEmpty) {
                return;
              }

              if (!popped) {
                popped = true;
                Navigator.of(context).pop(code);
              }
            },
          ),
          DottedBorder(
            strokeWidth: 8,
            dashPattern: const <double>[30, 35],
            // dashPattern: const <double>[50,90],
            // dashPattern: const <double>[50, 200],
            // dashPattern: const <double>[1, 190, 60, 190, 60, 190, 60, 170, 90],
            // dashPattern: const <double>[200, 50],
            strokeCap: StrokeCap.round,
            borderType: BorderType.RRect,
            radius: const Radius.circular(25),
            color: Colors.white,
            child: const SizedBox(
              height: 250,
              width: 250,
              // color: Colors.amber,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  alignment: Alignment.topCenter,
                  margin: const EdgeInsets.only(top: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back),
                        iconSize: 32.0,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.image),
                        iconSize: 32.0,
                        onPressed: () {
                          scanImage();
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  margin: const EdgeInsets.only(bottom: 80),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: IconButton(
                          icon: ValueListenableBuilder<TorchState>(
                            valueListenable: cameraController.torchState,
                            builder: (BuildContext context, TorchState state, Widget? child) {
                              switch (state) {
                                case TorchState.off:
                                  return const Icon(Icons.flashlight_off_rounded, color: Colors.white);
                                case TorchState.on:
                                  return const Icon(Icons.flashlight_on_rounded, color: Colors.yellow);
                              }
                            },
                          ),
                          iconSize: 38,
                          onPressed: () => cameraController.toggleTorch(),
                        ),
                      ),
                      const SizedBox(width: 50),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: IconButton(
                          color: Colors.white,
                          icon: ValueListenableBuilder<CameraFacing>(
                            valueListenable: cameraController.cameraFacingState,
                            builder: (BuildContext context, CameraFacing state, Widget? child) {
                              switch (state) {
                                case CameraFacing.front:
                                  return const Icon(Icons.camera_front);
                                case CameraFacing.back:
                                  return const Icon(Icons.camera_rear);
                              }
                            },
                          ),
                          iconSize: 38,
                          onPressed: () => cameraController.switchCamera(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
