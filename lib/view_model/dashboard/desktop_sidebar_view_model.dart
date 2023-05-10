import 'package:mobx/mobx.dart';

part 'desktop_sidebar_view_model.g.dart';

enum SidebarItem {
  dashboard,
  transactions,
  support,
  settings,
}

class DesktopSidebarViewModel = DesktopSidebarViewModelBase with _$DesktopSidebarViewModel;

abstract class DesktopSidebarViewModelBase with Store {
  DesktopSidebarViewModelBase();

  final _sidebarItemsToReset = [SidebarItem.support, SidebarItem.settings];

  @observable
  SidebarItem currentPage = SidebarItem.dashboard;

  @action
  void onPageChange(SidebarItem item) {
    if (currentPage == item && _sidebarItemsToReset.contains(item)) {
      resetSidebar();

      return;
    }
    currentPage = item;
  }

  @action
  void resetSidebar() {
    currentPage = SidebarItem.dashboard;
  }
}
