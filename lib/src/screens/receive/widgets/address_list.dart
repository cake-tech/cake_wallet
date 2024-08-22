import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/src/screens/nano_accounts/nano_account_list_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/address_cell.dart';
import 'package:cake_wallet/src/screens/receive/widgets/header_tile.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_account_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class AddressList extends StatelessWidget {
  const AddressList({
    super.key,
    required this.addressListViewModel,
    this.onSelect,
  });

  final WalletAddressListViewModel addressListViewModel;
  final Function(String)? onSelect;

  @override
  Widget build(BuildContext context) {
    bool editable = onSelect == null;
    return Observer(
      builder: (_) => ListView.separated(
        padding: EdgeInsets.all(0),
        separatorBuilder: (context, _) => const HorizontalSectionDivider(),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: addressListViewModel.items.length,
        itemBuilder: (context, index) {
          final item = addressListViewModel.items[index];
          Widget cell = Container();

          if (item is WalletAccountListHeader) {
            cell = HeaderTile(
                showTrailingButton: true,
                walletAddressListViewModel: addressListViewModel,
                trailingButtonTap: () async {
                  if (addressListViewModel.type == WalletType.monero ||
                      addressListViewModel.type == WalletType.haven) {
                    await showPopUp<void>(
                        context: context, builder: (_) => getIt.get<MoneroAccountListPage>());
                  } else {
                    await showPopUp<void>(
                        context: context, builder: (_) => getIt.get<NanoAccountListPage>());
                  }
                },
                title: S.of(context).accounts,
                trailingIcon: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).extension<ReceivePageTheme>()!.iconsColor,
                ));
          }

          if (item is WalletAddressListHeader) {
            cell = HeaderTile(
                title: S.of(context).addresses,
                walletAddressListViewModel: addressListViewModel,
                showTrailingButton: !addressListViewModel.isAutoGenerateSubaddressEnabled,
                showSearchButton: true,
                trailingButtonTap: () => Navigator.of(context).pushNamed(Routes.newSubaddress),
                trailingIcon: Icon(
                  Icons.add,
                  size: 20,
                  color: Theme.of(context).extension<ReceivePageTheme>()!.iconsColor,
                ));
          }

          if (item is WalletAddressListItem) {
            cell = Observer(builder: (_) {
              final isCurrent = item.address == addressListViewModel.address.address && editable;
              final backgroundColor = isCurrent
                  ? Theme.of(context).extension<ReceivePageTheme>()!.currentTileBackgroundColor
                  : Theme.of(context).extension<ReceivePageTheme>()!.tilesBackgroundColor;
              final textColor = isCurrent
                  ? Theme.of(context).extension<ReceivePageTheme>()!.currentTileTextColor
                  : Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor;

              return AddressCell.fromItem(
                item,
                isCurrent: isCurrent,
                hasBalance: addressListViewModel.isElectrumWallet,
                backgroundColor: backgroundColor,
                textColor: textColor,
                onTap: (_) {
                  if (onSelect != null) {
                    onSelect!(item.address);
                    return;
                  }
                  addressListViewModel.setAddress(item);
                },
                onEdit: editable
                    ? () => Navigator.of(context).pushNamed(Routes.newSubaddress, arguments: item)
                    : null,
              );
            });
          }

          return index != 0
              ? cell
              : ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  child: cell,
                );
        },
      ),
    );
  }
}
