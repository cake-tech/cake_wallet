import 'package:fast_scanner/fast_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

var isQrScannerShown = false;

Future<String> presentQRScanner(BuildContext context) async {
  isQrScannerShown = true;
  try {
    final result = await Navigator.of(context).push<Barcode>(
      MaterialPageRoute(
        builder:(context) {
          return BarcodeScannerSimple();
        },
      ),
    );
    isQrScannerShown = false;
    return (result?.rawValue??'').trim();
  } catch (e) {
    isQrScannerShown = false;
    rethrow;
  }
}

// https://github.com/MrCyjaneK/fast_scanner/blob/master/example/lib/barcode_scanner_simple.dart
class BarcodeScannerSimple extends StatefulWidget {
  const BarcodeScannerSimple({super.key});

  @override
  State<BarcodeScannerSimple> createState() => _BarcodeScannerSimpleState();
}

class _BarcodeScannerSimpleState extends State<BarcodeScannerSimple> {
  Barcode? _barcode;
  bool popped = false;
  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
      if (_barcode != null && popped != true) {
        setState(() {
          popped = true;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop(_barcode);
        });
      }
    }
  }

  final MobileScannerController ctrl = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          SwitchCameraButton(controller: ctrl),
          ToggleFlashlightButton(controller: ctrl),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
            controller: ctrl,
          ),
        ],
      ),
    );
  }
}


class ToggleFlashlightButton extends StatelessWidget {
  const ToggleFlashlightButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        switch (state.torchState) {
          case TorchState.auto:
            return IconButton(
              iconSize: 32.0,
              icon: const Icon(Icons.flash_auto),
              onPressed: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.off:
            return IconButton(
              iconSize: 32.0,
              icon: const Icon(Icons.flash_off),
              onPressed: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.on:
            return IconButton(
              iconSize: 32.0,
              icon: const Icon(Icons.flash_on),
              onPressed: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.unavailable:
            return const Icon(
              Icons.no_flash,
              color: Colors.grey,
            );
        }
      },
    );
  }
}

class SwitchCameraButton extends StatelessWidget {
  const SwitchCameraButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        final int? availableCameras = state.availableCameras;

        if (availableCameras != null && availableCameras < 2) {
          return const SizedBox.shrink();
        }

        final Widget icon;

        switch (state.cameraDirection) {
          case CameraFacing.front:
            icon = const Icon(Icons.camera_front);
          case CameraFacing.back:
            icon = const Icon(Icons.camera_rear);
        }

        return IconButton(
          iconSize: 32.0,
          icon: icon,
          onPressed: () async {
            await controller.switchCamera();
          },
        );
      },
    );
  }
}