import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class CakePhoneProductsPage extends BasePage {
  CakePhoneProductsPage();

  @override
  Widget body(BuildContext context) => CakePhoneProductsBody();

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).get_phone_number,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.title.color),
    );
  }
}

class CakePhoneProductsBody extends StatefulWidget {
  CakePhoneProductsBody();

  @override
  CakePhoneProductsBodyState createState() => CakePhoneProductsBodyState();
}

class CakePhoneProductsBodyState extends State<CakePhoneProductsBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Text(
                S.of(context).choose_phone_products,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryTextTheme.title.color,
                  fontFamily: 'Lato',
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.phoneNumberProduct);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryTextTheme.subhead.color,
                        Theme.of(context).primaryTextTheme.subhead.decorationColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          S.of(context).phone_number,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Text(
                          S.of(context).phone_number_product_description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
