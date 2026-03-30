import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:flutter/material.dart';

class DownloadAd extends StatelessWidget {
  const DownloadAd({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 48,
          children: [
            Text("Ready to try out Cake?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),),
            ClipRRect(borderRadius:BorderRadius.circular(16),child: QrImage(data: "https://cakewallet.com", size: MediaQuery.of(context).size.width*0.7,)),
            Text("Scan the code to download!")
          ],
        ),
      ),
    );
  }
}
