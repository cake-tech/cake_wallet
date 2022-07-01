import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/rounded_checkbox.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';

class IoniaFilterModal extends StatefulWidget {
  const IoniaFilterModal({@required this.categories});
  final List<IoniaCategory> categories;

  @override
  _IoniaFilterModalState createState() => _IoniaFilterModalState();
}

class _IoniaFilterModalState extends State<IoniaFilterModal> {
  List<IoniaCategory> _categories;

  @override
  void initState() {
    _categories = widget.categories;
    super.initState();
  }

  void _onSearchFilter(String text) {
    if (text.isEmpty) {
      _categories = widget.categories;
    } else {
      _categories = widget.categories
          .where(
            (e) => e.title.toLowerCase().contains(text.toLowerCase()),
          )
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchIcon = Padding(
      padding: EdgeInsets.all(8),
      child: Image.asset(
        'assets/images/search_icon.png',
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
                        onChanged: _onSearchFilter,
                        decoration: InputDecoration(
                          filled: true,
                          prefixIcon: searchIcon,
                          hintText: S.of(context).search_category,
                          contentPadding: EdgeInsets.only(bottom: 10),
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
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    itemBuilder: (_, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
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
                            RoundedCheckbox(
                              value: true,
                              onChanged: (onChanged) {},
                            )
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
            InkWell(
              onTap: () => Navigator.pop(context),
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
