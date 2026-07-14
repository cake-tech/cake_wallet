import 'dart:async';

import 'package:cake_wallet/entities/bridge_transfer.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/transaction_details/address_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/store/bridge_transfers_store.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

part 'bridge_details_view_model.g.dart';

class BridgeDetailsViewModel = BridgeDetailsViewModelBase with _$BridgeDetailsViewModel;

abstract class BridgeDetailsViewModelBase with Store {
  BridgeDetailsViewModelBase({
    required BridgeTransfer transferForDetails,
    required this.bridgeTransfersStore,
    required this.walletId,
  })  : items = ObservableList<TransactionDetailsListItem>(),
        transfer = _findTransferInStore(
                bridgeTransfersStore.bridgeTransfers, transferForDetails.id, walletId) ??
            transferForDetails {
    _updateItems();
    _setupReaction();
  }

  static BridgeTransfer? _findTransferInStore(
    List<BridgeTransfer> transfers,
    String transferId,
    String walletId,
  ) {
    try {
      return transfers.firstWhere(
        (t) => t.id == transferId && t.walletId == walletId,
      );
    } catch (_) {
      return null;
    }
  }

  final BridgeTransfersStore bridgeTransfersStore;
  final String walletId;
  ReactionDisposer? _reactionDisposer;

  @observable
  BridgeTransfer transfer;

  @observable
  ObservableList<TransactionDetailsListItem> items;

  Timer? timer;

  void _setupReaction() {
    _reactionDisposer = reaction(
      (_) => bridgeTransfersStore.bridgeTransfers,
      (_) => updateTransfer(),
    );
    updateTransfer();
  }

  @action
  void updateTransfer() {
    final updatedTransfer = _findTransferInStore(
      bridgeTransfersStore.bridgeTransfers,
      transfer.id,
      walletId,
    );
    if (updatedTransfer != null) {
      transfer = updatedTransfer;
      _updateItems();
    }
  }

  void dispose() {
    _reactionDisposer?.call();
    timer?.cancel();
  }

  void _updateItems() {
    items.clear();

    final statusText = transfer.statusMessage?.isNotEmpty == true
        ? '${_statusLabel(transfer.status)} · ${transfer.statusMessage}'
        : _statusLabel(transfer.status);

    items.add(
      DetailsListStatusItem(
        title: "Status",
        value: statusText,
        status: transfer.status,
      ),
    );

    final sourceName =
        evm?.getChainInfoByChainId(transfer.sourceChainId)?.name ?? '${transfer.sourceChainId}';
    final destName = evm?.getChainInfoByChainId(transfer.destinationChainId)?.name ??
        '${transfer.destinationChainId}';

    items.add(
      StandartListItem(
        title: "Source chain",
        value: sourceName,
      ),
    );

    items.add(
      StandartListItem(
        title: "Destination chain",
        value: destName,
      ),
    );

    items.add(
      StandartListItem(
        title: "Amount",
        value: '${transfer.amount} ${transfer.tokenSymbol}',
      ),
    );

    items.add(
      AddressListItem(
        title: "Recipient",
        value: transfer.recipientAddress,
      ),
    );

    final sourceExplorerUrl = evm?.getExplorerUrlForChainId(transfer.sourceChainId);
    final sourceTxUrl = sourceExplorerUrl != null && sourceExplorerUrl.isNotEmpty
        ? '$sourceExplorerUrl/tx/${transfer.sourceTxHash}'
        : null;

    if (sourceTxUrl != null) {
      final explorerDescription = S.current.view_transaction_on + Uri.parse(sourceTxUrl).host;
      items.add(
        TrackTradeListItem(
          title: explorerDescription,
          value: sourceTxUrl,
          onTap: () => _launchUrl(sourceTxUrl),
        ),
      );
    }

    if (transfer.errorMessage != null && transfer.errorMessage!.isNotEmpty) {
      items.add(
        StandartListItem(
          title: "Error",
          value: transfer.errorMessage!,
        ),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'submitted':
        return "Submitted";
      case 'confirming':
        return "Confirming on source";
      case 'initiated':
        return "Bridge initiated";
      case 'completed':
        return "Completed";
      case 'failed':
        return "Failed";
      default:
        return status;
    }
  }

  void _launchUrl(String url) {
    final uri = Uri.parse(url);
    try {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
