import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/rounded_checkbox.dart';
import 'package:cake_wallet/view_model/ionia/ionia_filter_view_model.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class IoniaFilterModal extends StatelessWidget {
  IoniaFilterModal({
    @required this.filterViewModel,
    @required this.selectedCategories,
  }) {
    filterViewModel.setSelectedCategories(this.selectedCategories);
  }

  final IoniaFilterViewModel filterViewModel;
  final List<IoniaCategory> selectedCategories;

  @override
  Widget build(BuildContext context) {
    final searchIcon = Padding(
      padding: EdgeInsets.all(10),
      child: Image.asset(
        'assets/images/mini_search_icon.png',
        color: Theme.of(context).accentColor,
      ),
    );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AlertBackground(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.only(top: 24, bottom: 20),
              margin: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).backgroundColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24),
                      child: TextField(
                        onChanged: filterViewModel.onSearchFilter,
                        style: textMedium(
                          color: Theme.of(context).primaryTextTheme.title.color,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          prefixIcon: searchIcon,
                          hintText: S.of(context).search_category,
                          contentPadding: EdgeInsets.only(bottom: 5),
                          fillColor: Theme.of(context).textTheme.subhead.backgroundColor,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(thickness: 2),
                  SizedBox(height: 24),
                  Observer(builder: (_) {
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: filterViewModel.ioniaCategories.length,
                      itemBuilder: (_, index) {
                        final category = filterViewModel.ioniaCategories[index];
                        return Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                          child: InkWell(
                            onTap: () => filterViewModel.selectFilter(category),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      category.iconPath,
                                      color: Theme.of(context).primaryTextTheme.title.color,
                                    ),
                                    SizedBox(width: 10),
                                    Text(category.title,
                                        style: textSmall(
                                          color: Theme.of(context).primaryTextTheme.title.color,
                                        ).copyWith(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                Observer(builder: (_) {
                                  final value = filterViewModel.selectedIndices;
                                  return RoundedCheckbox(
                                    value: value.contains(category.index),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
            InkWell(
              onTap: () => Navigator.pop(context, filterViewModel.selectedCategories),
              child: Container(
                margin: EdgeInsets.only(bottom: 40),
                child: CircleAvatar(
                  child: Icon(
                    Icons.close,
                    color: Colors.black,
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
