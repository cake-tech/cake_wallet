
class BuyException implements Exception {
  BuyException({required this.title, required this.content});

  final String title;
  final String content;

  @override
  String toString() => '$title: $content';
}