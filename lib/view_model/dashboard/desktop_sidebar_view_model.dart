import 'package:mobx/mobx.dart';

part 'desktop_sidebar_view_model.g.dart';

enum SidebarItem {
  dashboard(0),
  support(1),
  settings(2),
  transactions(3);

  final int value;
  const SidebarItem(this.value);
}

class DesktopSidebarViewModel = DesktopSidebarViewModelBase with _$DesktopSidebarViewModel;

abstract class DesktopSidebarViewModelBase with Store {
  DesktopSidebarViewModelBase();

  @observable
  SidebarItem currentPage = SidebarItem.dashboard;


  @action
  void onPageChange(SidebarItem item) {
    currentPage = item;
  }

  @action
  void resetSidebar() {
    currentPage = SidebarItem.dashboard;
  }
}
