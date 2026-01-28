import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/wallet_restore_choose_derivation_view_model.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class WalletRestoreChooseDerivationPage extends BasePage {
  WalletRestoreChooseDerivationPage(this.walletRestoreChooseDerivationViewModel) {}

  @override
  Widget middle(BuildContext context) => Text(
        S.current.choose_derivation,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary),
      );

  final WalletRestoreChooseDerivationViewModel walletRestoreChooseDerivationViewModel;

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) => FutureBuilder<List<DerivationInfo>>(
        future: walletRestoreChooseDerivationViewModel.derivations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Error! No derivations available!'));
          } else {
            return ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (_, __) => SizedBox(),
              itemCount: snapshot.data!.length,
              itemBuilder: (__, index) {
                final derivation = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () async {
                      Navigator.pop(context, derivation);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Center(
                        child: Text(
                          "${derivation.description ?? derivation.derivationType.toString().split('.').last}",
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (derivation.derivationPath != null)
                            Text(
                              derivation.derivationPath!,
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          Text(
                            derivation.address,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            "${S.current.confirmed}: ${derivation.balance}",
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            "${S.current.transactions}: ${derivation.transactionsCount}",
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
