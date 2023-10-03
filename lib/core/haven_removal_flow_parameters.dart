import 'package:cake_wallet/view_model/haven_removal_view_model.dart';
import 'package:cw_core/wallet_base.dart';

class HavenRemovalFlowParameters {
  final WalletBase wallet;
  final bool isFromRemoveHavenAppStartFlow;
  final HavenRemovalViewModel? havenRemovalViewModel;

  HavenRemovalFlowParameters(
    this.wallet,
    this.isFromRemoveHavenAppStartFlow,
    this.havenRemovalViewModel,
  );
}
