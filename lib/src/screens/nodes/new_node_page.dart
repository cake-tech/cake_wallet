import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/node_list/node_list_store.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class NewNodePage extends BasePage {
  @override
  String get title => S.current.node_new;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) => NewNodePageForm();
}

class NewNodePageForm extends StatefulWidget {
  @override
  NewNodeFormState createState() => NewNodeFormState();
}

class NewNodeFormState extends State<NewNodePageForm> {
  final _formKey = GlobalKey<FormState>();
  final _nodeAddressController = TextEditingController();
  final _nodePortController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nodeAddressController.dispose();
    _nodePortController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void onHandleControllers(NodeListStore nodeListStore) {
    if (_nodeAddressController.text.isNotEmpty &&
        _nodePortController.text.isNotEmpty) {
      nodeListStore.setDisabledState(false);
    } else {
      nodeListStore.setDisabledState(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodeList = Provider.of<NodeListStore>(context);

    _nodeAddressController.addListener(() {onHandleControllers(nodeList);});
    _nodePortController.addListener(() {onHandleControllers(nodeList);});

    return Container(
      color: PaletteDark.historyPanel,
      padding: EdgeInsets.only(left: 24, right: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 24.0),
        content: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white
                      ),
                      decoration: InputDecoration(
                          hintStyle:
                          TextStyle(
                              color: PaletteDark.walletCardText,
                              fontSize: 16
                          ),
                          hintText: S.of(context).node_address,
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: PaletteDark.menuList,
                                  width: 1.0)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: PaletteDark.menuList,
                                  width: 1.0))),
                      controller: _nodeAddressController,
                      validator: (value) {
                        nodeList.validateNodeAddress(value);
                        return nodeList.errorMessage;
                      },
                    ),
                  )
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                          signed: false, decimal: false),
                      decoration: InputDecoration(
                          hintStyle:
                          TextStyle(
                              color: PaletteDark.walletCardText,
                              fontSize: 16
                          ),
                          hintText: S.of(context).node_port,
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: PaletteDark.menuList,
                                  width: 1.0)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: PaletteDark.menuList,
                                  width: 1.0))),
                      controller: _nodePortController,
                      validator: (value) {
                        nodeList.validateNodePort(value);
                        return nodeList.errorMessage;
                      },
                    ),
                  )
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white
                      ),
                      decoration: InputDecoration(
                          hintStyle:
                          TextStyle(
                              color: PaletteDark.walletCardText,
                              fontSize: 16
                          ),
                          hintText: S.of(context).login,
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: PaletteDark.menuList,
                                  width: 1.0)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: PaletteDark.menuList,
                                  width: 1.0))),
                      controller: _loginController,
                      validator: (value) => null,
                    ),
                  )
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white
                      ),
                      decoration: InputDecoration(
                          hintStyle:
                          TextStyle(
                              color: PaletteDark.walletCardText,
                              fontSize: 16
                          ),
                          hintText: S.of(context).password,
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: PaletteDark.menuList,
                                  width: 1.0)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: PaletteDark.menuList,
                                  width: 1.0))),
                      controller: _passwordController,
                      validator: (value) => null,
                    ),
                  )
                ],
              )
            ],
          )
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24),
        bottomSection: Observer(
          builder: (_) => Row(
            children: <Widget>[
              Flexible(
                  child: Container(
                    padding: EdgeInsets.only(right: 8.0),
                    child: PrimaryButton(
                        onPressed: () {
                          _nodeAddressController.text = '';
                          _nodePortController.text = '';
                          _loginController.text = '';
                          _passwordController.text = '';
                        },
                        text: S.of(context).reset,
                        color: Colors.red,
                        textColor: Colors.white),
                  )),
              Flexible(
                  child: Container(
                    padding: EdgeInsets.only(left: 8.0),
                    child: PrimaryButton(
                      onPressed: () async {
                        if (!_formKey.currentState.validate()) {
                          return;
                        }

                        await nodeList.addNode(
                            address: _nodeAddressController.text,
                            port: _nodePortController.text,
                            login: _loginController.text,
                            password: _passwordController.text);

                        Navigator.of(context).pop();
                      },
                      text: S.of(context).save,
                      color: Colors.green,
                      textColor: Colors.white,
                      isDisabled: nodeList.disabledState,
                    ),
                  )),
            ],
          )
        ),
      )
    );
  }
}
