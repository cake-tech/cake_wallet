import 'dart:async';

class SideMenuController {
  late int _currentPage;

  int get currentPage => _currentPage;

  SideMenuController({int initialPage = 0}) {
    _currentPage = initialPage;
  }
  final _streameController = StreamController<int>.broadcast();

  Stream<int> get stream => _streameController.stream;

  void changePage(int index) {
    _currentPage = index;
    _streameController.sink.add(index);
  }

  void dispose() {
    _streameController.close();
  }

  void addListener(void Function(int) listener) {
    _streameController.stream.listen(listener);
  }

  void removeListener(void Function(int) listener) {
    _streameController.stream.listen(listener).cancel();
  }
}

class SideMenuGlobal {
  static late SideMenuController controller;
}
