import 'package:mobx/mobx.dart';

part 'page_view_store.g.dart';

class PageViewStore = PageViewStoreBase with _$PageViewStore;

abstract class PageViewStoreBase with Store {
  PageViewStoreBase() {
    setCurrentPage(1);
  }

  @observable
  double currentPage;

  @action
  void setCurrentPage(double currentPage) {
    this.currentPage = currentPage;
  }
}