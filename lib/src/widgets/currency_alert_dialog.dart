import 'dart:ui';

import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:flutter/material.dart';

class CurrencyAlertDialog extends StatelessWidget {
  const CurrencyAlertDialog(this.onCurrencySelect, {Key key}) : super(key: key);

  final Function(FiatCurrency) onCurrencySelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          child: Container(
            color: Color(0xff010615).withOpacity(0.8),
            child: Center(
              child: Column(
                children: [
                  Expanded(child: const SizedBox()),
                  Text(
                    "Change Currency",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 50),
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    child: Container(
                      height: 400,
                      width: 300,
                      color: Color(0xff456EFF),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: FiatCurrency.all.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.all(0.1),
                            child: Material(
                              child: InkWell(
                                onTap: () {
                                  onCurrencySelect(FiatCurrency.all[index]);
                                },
                                splashColor: Color(0xff456EFF).withOpacity(0.1),
                                highlightColor: Color(0xff456EFF).withOpacity(0.1),
                                child: Center(
                                  child: Text(
                                    FiatCurrency.all[index].title,
                                    style: TextStyle(
                                      color: Color(0xff355688),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(child: const SizedBox()),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Color(0xff010615),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
