import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:mobx/mobx.dart';

part 'ionia_filter_view_model.g.dart';

class IoniaFilterViewModel = IoniaFilterViewModelBase with _$IoniaFilterViewModel;

abstract class IoniaFilterViewModelBase with Store {
  IoniaFilterViewModelBase() {
    selectedIndices = ObservableList<int>();
    ioniaCategories = IoniaCategory.allCategories;
  }

  List<IoniaCategory> get selectedCategories => ioniaCategories.where(_isSelected).toList();

  @observable
  ObservableList<int> selectedIndices;

  @observable
  List<IoniaCategory> ioniaCategories;

  @action
  void selectFilter(IoniaCategory ioniaCategory) {
    if (ioniaCategory == IoniaCategory.all && !selectedIndices.contains(0)) {
      selectedIndices.clear();
      selectedIndices.add(0);
      return;
    }
    if (selectedIndices.contains(ioniaCategory.index) && ioniaCategory.index != 0) {
      selectedIndices.remove(ioniaCategory.index);
      return;
    }
    selectedIndices.add(ioniaCategory.index);
    selectedIndices.remove(0);
  }

  @action
  void onSearchFilter(String text) {
    if (text.isEmpty) {
      ioniaCategories = IoniaCategory.allCategories;
    } else {
      ioniaCategories = IoniaCategory.allCategories
          .where(
            (e) => e.title.toLowerCase().contains(text.toLowerCase()),
          )
          .toList();
    }
  }

  @action
  void setSelectedCategories(List<IoniaCategory> selectedCategories) {
    selectedIndices = ObservableList.of(selectedCategories.map((e) => e.index));
  }

  bool _isSelected(IoniaCategory ioniaCategory) {
    return selectedIndices.contains(ioniaCategory.index);
  }
}
