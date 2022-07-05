import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'ionia_filter_view_model.g.dart';

class IoniaFilterViewModel =  IoniaFilterViewModelBase with _$IoniaFilterViewModel;

abstract class IoniaFilterViewModelBase with Store {

   IoniaFilterViewModelBase({@required this.ioniaCategorySource}){
    selectedFilters = ioniaCategorySource.values.map((e) => e.title).toList();
    ioniaCategories = IoniaCategory.allCategories;
    ioniaCategorySource.watch().listen((event) {
       selectedFilters = ioniaCategorySource.values.map((e) => e.title).toList(); 
    });
  }

  Box<IoniaCategory> ioniaCategorySource;

  @observable
  List<String> selectedFilters; 


  @observable
  List<IoniaCategory> ioniaCategories;


  @action
  void selectFilter(IoniaCategory ioniaCategory){
    if(ioniaCategory == IoniaCategory.all && !ioniaCategorySource.containsKey(0)){
      final keys = ioniaCategorySource.keys;
      ioniaCategorySource.deleteAll(keys);
      ioniaCategorySource.put(0, ioniaCategory);
      return;
    }
    if(selectedFilters.contains(ioniaCategory.title) && ioniaCategory.index != 0){
     ioniaCategorySource.delete(ioniaCategory.index);
     return;
    }
    ioniaCategorySource.put(ioniaCategory.index, ioniaCategory);
    ioniaCategorySource.delete(0);
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

}