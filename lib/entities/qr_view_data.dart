class QrViewData {
  QrViewData({
    this.version,
    this.heroTag,
    required this.data,
    this.embeddedImagePath,
  });
  
  final int? version;
  final String? heroTag;
  final String data;
  final String? embeddedImagePath;
}
