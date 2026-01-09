import 'package:cake_wallet/new-ui/widgets/receive_page/receive_address_type_selector.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ReceiveSeedTypeDisplay extends StatelessWidget {
  const ReceiveSeedTypeDisplay({super.key, required this.receiveOptionViewModel});

  final ReceiveOptionViewModel receiveOptionViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showPicker(context),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12.0,
          children: [
            if (receiveOptionViewModel.selectedReceiveOption.iconPath != null)
              SvgPicture.asset(
                width: 32,
                height: 32,
                receiveOptionViewModel.selectedReceiveOption.iconPath!,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            Text(
              receiveOptionViewModel.selectedReceiveOption.value,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(999999),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () => _showPicker(context),
                icon: (Icon(
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                  Icons.keyboard_arrow_down,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) async {
    showCupertinoModalBottomSheet(
        context: context,
        builder: (context) {
          return Material(
              child: ReceiveAddressTypeSelector(
            receiveOptionViewModel: receiveOptionViewModel,
          ));
        });
  }
}
