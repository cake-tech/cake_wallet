import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:flutter/material.dart';

late PageController parallaxController;

class GradientBackground extends StatefulWidget {
  const GradientBackground({required this.scaffold});

  final Widget scaffold;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground> {
  late double _pageOffset;

  @override
  void initState() {
    super.initState();
    _pageOffset = 0;
    parallaxController = PageController(initialPage: 0);
    parallaxController.addListener(
          () => setState(() => _pageOffset = parallaxController.page ?? 0),
    );
  }

  @override
  void dispose() {
    parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DataImage(
          pageCount: 4,
          screenSize: MediaQuery.of(context).size,
          offset: _pageOffset,
        ),
        widget.scaffold,
      ],
    );
  }
}

class DataImage extends StatelessWidget {
  const DataImage({
    Key? key,
    required this.pageCount,
    required this.screenSize,
    required this.offset,
  }) : super(key: key);

  final Size screenSize;
  final int pageCount;
  final double offset;

  @override
  Widget build(BuildContext context) {
    int lastPageIdx = pageCount - 1;
    int firstPageIdx = 0;
    int alignmentMax = 1;
    int alignmentMin = -1;
    int pageRange = (lastPageIdx - firstPageIdx) - 1;
    int alignmentRange = (alignmentMax - alignmentMin);
    double alignment = (((offset - firstPageIdx) * alignmentRange) / pageRange) + alignmentMin;

    return SizedBox(
      height: screenSize.height,
      width: screenSize.width,
      child: Image(
        image: const AssetImage('assets/images/background_test.png'),
        alignment: Alignment(alignment, 0),
        fit: BoxFit.fitHeight,
      ),
    );
  }
}
