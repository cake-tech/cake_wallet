import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_edit_or_create_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobx/mobx.dart';

const List<String> defaultLabels = [
  "Donation",
  "Savings",
  "Business",
  "Mining",
  "Salary"
];

class ReceiveLabelModal extends StatefulWidget {
  const ReceiveLabelModal({super.key, required this.walletAddressEditOrCreateViewModel});

  final WalletAddressEditOrCreateViewModel walletAddressEditOrCreateViewModel;



  @override
  State<ReceiveLabelModal> createState() => _ReceiveLabelModalState();
}

class _ReceiveLabelModalState extends State<ReceiveLabelModal> {
  late final TextEditingController _controller;


  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = widget.walletAddressEditOrCreateViewModel.label;


    });
    reaction((_) => widget.walletAddressEditOrCreateViewModel.state, (AddressEditOrCreateState state) {
      if (state is AddressSavedSuccessfully) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop(widget.walletAddressEditOrCreateViewModel.label);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      child: Column(
        spacing: 24,
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTopBar(title: "Label Address", leadingIcon: Icon(Icons.close), onLeadingPressed: Navigator.of(context).pop, onTrailingPressed: (){}),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              spacing: 24,
              children: [
                Text("You can access and manage all your previously used addressses by pressing Addresses",textAlign: TextAlign.center,


                  style: TextStyle(fontSize:12, color:Theme.of(context).colorScheme.onSurfaceVariant),),
                NewListSections(sections: {"":[
                  ListItemTextField(keyValue: "label", label: "Label")
                ]}, controllers: {"label": _controller}),

                SizedBox(
                  height:36,
                  child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: defaultLabels.length,
                      separatorBuilder: (context, index){
                        return SizedBox(width:8);
                      },
                      itemBuilder: (context, index){
                        return Container(
                          height: 36,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(999)
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: (){
                                _controller.text = defaultLabels[index];
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Center(
                                  child: Text(defaultLabels[index], style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).colorScheme.primary
                                  ),),
                                ),
                              ),
                            ),
                          ),
                        );

                      }
                  ),
                ),

                NewPrimaryButton(onPressed: (){
                  widget.walletAddressEditOrCreateViewModel.label = _controller.text;
                  widget.walletAddressEditOrCreateViewModel.save();
                }, text: "Continue", color: Theme.of(context).colorScheme.primary, textColor: Theme.of(context).colorScheme.onPrimary)
              ]
            ),
          ),
          SizedBox()
            ],
          )
    );
  }
}
