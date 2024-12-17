import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TransactionDetailsPage extends BasePage {
  TransactionDetailsPage({required this.transactionDetailsViewModel}) {
    if (transactionDetailsViewModel.sendViewModel.isElectrumWallet) {
      bitcoin!.updateFeeRates(transactionDetailsViewModel.sendViewModel.wallet);
    }
  }

  @override
  String get title => S.current.transaction_details_title;

  final TransactionDetailsViewModel transactionDetailsViewModel;

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SectionStandardList(
            sectionCount: 1,
            itemCounter: (int _) => transactionDetailsViewModel.items.length,
            itemBuilder: (__, index) {
              final item = transactionDetailsViewModel.items[index];

              if (item is StandartListItem) {
                return GestureDetector(
                  key: item.key,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.value));
                    showBar<void>(context, S.of(context).transaction_details_copied(item.title));
                  },
                  child: ListRow(title: '${item.title}:', value: item.value),
                );
              }

              if (item is BlockExplorerListItem) {
                return GestureDetector(
                  key: item.key,
                  onTap: item.onTap,
                  child: ListRow(title: '${item.title}:', value: item.value),
                );
              }

              if (item is TextFieldListItem) {
                return TextFieldListRow(
                  key: item.key,
                  title: item.title,
                  value: item.value,
                  onSubmitted: item.onSubmitted,
                );
              }

              return Container();
            },
          ),
        ),
        Observer(
          builder: (_) {
            if (transactionDetailsViewModel.canReplaceByFee) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: SelectButton(
                  text: S.of(context).bump_fee,
                  onTap: () async {
                    Navigator.of(context).pushNamed(Routes.bumpFeePage,
                        arguments: [transactionDetailsViewModel.transactionInfo, transactionDetailsViewModel.rawTransaction]);
                  },
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ],
    );
  }
}
