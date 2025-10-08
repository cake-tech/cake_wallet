import 'package:cake_wallet/core/node_address_validator.dart';
import 'package:cake_wallet/core/node_port_validator.dart';
import 'package:cake_wallet/core/socks_proxy_node_address_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class NodeForm extends StatefulWidget {
  NodeForm({
    required this.nodeViewModel,
    required this.formKey,
    this.editingNode,
    this.type,
  });

  final NodeCreateOrEditViewModel nodeViewModel;
  final GlobalKey<FormState> formKey;
  final Node? editingNode;
  final WalletType? type;

  @override
  State<StatefulWidget> createState() => _NodeFormState(editingNode: this.editingNode);
}

class _NodeFormState extends State<NodeForm> {
  _NodeFormState({
    Node? editingNode,
  })  : _addressController = TextEditingController(text: editingNode?.uri.host.toString()),
        _pathController = TextEditingController(text: editingNode?.path.toString()),
        _portController = TextEditingController(
            text: (editingNode != null && editingNode.uri.hasPort)
                ? editingNode.uri.port.toString()
                : ''),
        _loginController = TextEditingController(text: editingNode?.login),
        _passwordController = TextEditingController(text: editingNode?.password),
        _socksAddressController = TextEditingController(text: editingNode?.socksProxyAddress) {
    if (editingNode != null) {
      widget.nodeViewModel
        ..setAddress((editingNode.uri.host.toString()))
        ..setPath((editingNode.path.toString()))
        ..setPort((editingNode.uri.hasPort ? editingNode.uri.port.toString() : ''))
        ..setPassword((editingNode.password ?? ''))
        ..setLogin((editingNode.login ?? ''))
        ..setSSL((editingNode.isSSL))
        ..setTrusted((editingNode.trusted))
        ..setIsEnabledForAutoSwitching((editingNode.isEnabledForAutoSwitching))
        ..setSocksProxy((editingNode.useSocksProxy))
        ..setSocksProxyAddress((editingNode.socksProxyAddress ?? ''));
    }

    if (widget.nodeViewModel.hasAuthCredentials) {
      reaction((_) => widget.nodeViewModel.login, (String login) {
        if (login != _loginController.text) _loginController.text = login;
      });

      reaction((_) => widget.nodeViewModel.password, (String password) {
        if (password != _passwordController.text) _passwordController.text = password;
      });
    }
    reaction((_) => widget.nodeViewModel.address, (String address) {
      if (address != _addressController.text) {
        _addressController.text = address;
      }
    });

    reaction((_) => widget.nodeViewModel.port, (String port) {
      if (port != _portController.text) _portController.text = port;
    });

    reaction((_) => widget.nodeViewModel.path, (String path) {
      if (path != _pathController.text) _pathController.text = path;
    });

    _addressController.addListener(() => widget.nodeViewModel.address = _addressController.text);
    _pathController.addListener(() => widget.nodeViewModel.path = _pathController.text);
    _portController.addListener(() => widget.nodeViewModel.port = _portController.text);
    _loginController.addListener(() => widget.nodeViewModel.login = _loginController.text);
    _passwordController.addListener(() => widget.nodeViewModel.password = _passwordController.text);
    _socksAddressController
        .addListener(() => widget.nodeViewModel.socksProxyAddress = _socksAddressController.text);
  }

  final TextEditingController _addressController;
  final TextEditingController _pathController;
  final TextEditingController _portController;
  final TextEditingController _loginController;
  final TextEditingController _passwordController;
  final TextEditingController _socksAddressController;

  @override
  Widget build(BuildContext context) => Form(
        key: widget.formKey,
        child: Column(children: <Widget>[
          Row(children: <Widget>[
            Expanded(
              child: BaseTextFormField(
                controller: _addressController,
                hintText: S.of(context).node_address,
                validator: widget.type == WalletType.decred
                    ? NodeAddressValidatorDecredBlankException()
                    : NodeAddressValidator(),
              ),
            )
          ]),
          const SizedBox(height: 10),
          if (widget.nodeViewModel.hasPathSupport) ...[
            Row(children: <Widget>[
              Expanded(
                child: BaseTextFormField(
                  controller: _pathController,
                  hintText: "/path",
                  validator: NodePathValidator(),
                ),
              )
            ]),
            const SizedBox(height: 10),
          ],
          Row(children: <Widget>[
            Expanded(
              child: BaseTextFormField(
                controller: _portController,
                hintText: S.of(context).node_port,
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                validator: NodePortValidator(),
              ),
            )
          ]),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Observer(
                  builder: (_) => StandardCheckbox(
                    value: widget.nodeViewModel.useSSL,
                    borderColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    iconColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) => widget.nodeViewModel.useSSL = value,
                    caption: S.of(context).use_ssl,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Observer(
                  builder: (_) => StandardCheckbox(
                    value: widget.nodeViewModel.isEnabledForAutoSwitching,
                    borderColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    iconColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) => widget.nodeViewModel.isEnabledForAutoSwitching = value,
                    caption: S.current.enable_for_auto_switching,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (widget.nodeViewModel.hasAuthCredentials) ...[
            Row(children: <Widget>[
              Expanded(
                child: BaseTextFormField(
                  controller: _loginController,
                  hintText: S.of(context).login,
                ),
              )
            ]),
            const SizedBox(height: 10),
            Row(children: <Widget>[
              Expanded(
                child: BaseTextFormField(
                  controller: _passwordController,
                  hintText: S.of(context).password,
                ),
              )
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Observer(
                    builder: (_) => StandardCheckbox(
                      value: widget.nodeViewModel.trusted,
                      borderColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      iconColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) => widget.nodeViewModel.trusted = value,
                      caption: S.of(context).trusted,
                    ),
                  ),
                ],
              ),
            ),
            Observer(
              builder: (_) => Column(children: [
                if (widget.nodeViewModel.usesEmbeddedProxy) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        StandardCheckbox(
                          value: widget.nodeViewModel.usesEmbeddedProxy,
                          gradientBackground: false,
                          borderColor: Theme.of(context).dividerColor,
                          iconColor: Theme.of(context).colorScheme.primary,
                          onChanged: null,
                          caption: 'Embedded Tor SOCKS Proxy',
                        ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      StandardCheckbox(
                        value: widget.nodeViewModel.useSocksProxy,
                        borderColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        iconColor: Theme.of(context).colorScheme.primary,
                        onChanged: (value) {
                          if (!value) _socksAddressController.text = '';
                          widget.nodeViewModel.useSocksProxy = value;
                        },
                        caption: 'SOCKS Proxy',
                      ),
                    ],
                  ),
                ),
                if (widget.nodeViewModel.useSocksProxy) ...[
                  const SizedBox(height: 10),
                  Row(children: <Widget>[
                    Expanded(
                      child: BaseTextFormField(
                        controller: _socksAddressController,
                        hintText: '[<ip>:]<port>',
                        validator: SocksProxyNodeAddressValidator(),
                      ),
                    )
                  ]),
                ]
              ]),
            ),
          ]
        ]),
      );
}
