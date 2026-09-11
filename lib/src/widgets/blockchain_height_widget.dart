import 'dart:math';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:cake_wallet/utils/date_picker.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/decred/decred.dart';

class BlockchainHeightWidget extends StatefulWidget {
  BlockchainHeightWidget({
    GlobalKey? key,
    this.onHeightChange,
    this.focusNode,
    this.onHeightOrDateEntered,
    this.hasDatePicker = true,
    this.isSilentPaymentsScan = false,
    this.isMwebScan = false,
    this.toggleSingleScan,
    this.doSingleScan = false,
    this.historicalMode = true,
    this.toggleHistoricalMode,
    this.bitcoinMempoolAPIEnabled,
    required this.walletType,
    this.blockHeightTextFieldKey,
    this.heightController,
    this.workerCount = 1,
    this.maxWorkerCount = 1,
    this.supportsParallelScanning = false,
    this.onWorkerCountChanged,
  }) : super(key: key);

  final Function(int)? onHeightChange;
  final Function(bool)? onHeightOrDateEntered;
  final FocusNode? focusNode;
  final bool hasDatePicker;
  final bool isSilentPaymentsScan;
  final bool isMwebScan;
  final TextEditingController? heightController;
  final bool doSingleScan;
  final bool historicalMode;
  final Function()? toggleHistoricalMode;
  final Future<bool>? bitcoinMempoolAPIEnabled;
  final Function()? toggleSingleScan;
  final WalletType walletType;
  final Key? blockHeightTextFieldKey;
  // Rescan-page worker-count slider (Silent Payments only). Locked at 1
  // (supportsParallelScanning false) until the connected node has
  // negotiated the v2 wire protocol - see RescanViewModel.supportsParallelScanning.
  final int workerCount;
  final int maxWorkerCount;
  final bool supportsParallelScanning;
  final ValueChanged<int>? onWorkerCountChanged;
  @override
  State<StatefulWidget> createState() => BlockchainHeightState();
}

class BlockchainHeightState extends State<BlockchainHeightWidget> {
  final dateController = TextEditingController();
  late final TextEditingController restoreHeightController;

  int get height => _height;
  int _height = 0;

  @override
  void initState() {
    restoreHeightController = widget.heightController ?? TextEditingController();

    restoreHeightController.addListener(() {
      if (restoreHeightController.text.isNotEmpty) {
        widget.onHeightOrDateEntered?.call(true);
      } else {
        widget.onHeightOrDateEntered?.call(false);
        dateController.text = '';
      }
      try {
        final int _height;
        if (restoreHeightController.text.isNotEmpty) {
          final digits = restoreHeightController.text.replaceAll(RegExp(r'[^0-9]'), '');
          _height = int.tryParse(digits) ?? 0;
        } else {
          _height = 0;
        }
        _changeHeight(_height);
      } catch (_) {
        _changeHeight(0);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Container(
                padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: BaseTextFormField(
                  key: widget.blockHeightTextFieldKey,
                  focusNode: widget.focusNode,
                  controller: restoreHeightController,
                  keyboardType: TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  hintText: widget.isSilentPaymentsScan
                      ? S.of(context).silent_payments_scan_from_height
                      : S.of(context).widgets_restore_from_blockheight,
                ),
              ),
            )
          ],
        ),
        if (widget.hasDatePicker) ...[
          Padding(
            padding: EdgeInsets.only(top: 15, bottom: 15),
            child: Text(
              S.of(context).widgets_or,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Row(
            children: <Widget>[
              Flexible(
                  child: Container(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: IgnorePointer(
                    child: BaseTextFormField(
                      controller: dateController,
                      hintText: widget.isSilentPaymentsScan
                          ? S.of(context).silent_payments_scan_from_date
                          : S.of(context).widgets_restore_from_date,
                    ),
                  ),
                ),
              ))
            ],
          ),
          if (widget.isSilentPaymentsScan) ...[
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).scan_one_block,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StandardSwitch(
                      value: widget.doSingleScan,
                      onTapped: () => widget.toggleSingleScan?.call(),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                S.of(context).silent_payments_scan_one_block_description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
          if (widget.isSilentPaymentsScan) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).silent_payments_historical_mode,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StandardSwitch(
                      value: widget.historicalMode,
                      onTapped: () => widget.toggleHistoricalMode?.call(),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                S.of(context).silent_payments_historical_mode_description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
          // Worker-count slider: irrelevant for a single-block scan (that
          // path always uses exactly one worker on an unpartitioned range
          // regardless of this value - see ElectrumWalletBase._setListeners),
          // so hidden rather than shown-but-inert while doSingleScan is on.
          if (widget.isSilentPaymentsScan && !widget.doSingleScan)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).silent_payments_scan_worker_count,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        '${widget.supportsParallelScanning ? widget.workerCount : 1}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  Slider(
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: context.customColors.toggleColorOffState,
                    thumbColor: context.customColors.toggleKnobStateColor,
                    value: (widget.supportsParallelScanning ? widget.workerCount : 1).toDouble(),
                    min: 1,
                    max: max(widget.maxWorkerCount, 1).toDouble(),
                    divisions: max(widget.maxWorkerCount - 1, 1),
                    onChanged: widget.supportsParallelScanning
                        ? (v) => widget.onWorkerCountChanged?.call(v.round())
                        : null,
                  ),
                  if (!widget.supportsParallelScanning)
                    Text(
                      S.of(context).silent_payments_scan_worker_count_locked,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: 40, right: 40, top: 24),
            child: Text(
              widget.isSilentPaymentsScan
                  ? S.of(context).silent_payments_scan_from_date_or_blockheight
                  : S.of(context).restore_from_date_or_blockheight,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        ]
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await getDate(
        context: context,
        initialDate: now.subtract(Duration(days: 1)),
        firstDate: DateTime(2014, DateTime.may),
        lastDate: now);

    if (date != null) {
      int height;
      if (widget.isMwebScan) {
        height = bitcoin!.getLitecoinHeightByDate(date: date);
      } else if (widget.isSilentPaymentsScan) {
        height = await bitcoin!.getHeightByDate(
          date: date,
          bitcoinMempoolAPIEnabled: await widget.bitcoinMempoolAPIEnabled,
        );
      } else {
        if (widget.walletType == WalletType.decred) {
          height = decred!.heightByDate(date);
        } else if (widget.walletType == WalletType.monero) {
          height = monero!.getHeightByDate(date: date);
        } else if (widget.walletType == WalletType.wownero) {
          height = wownero!.getHeightByDate(date: date);
        } else if (widget.walletType == WalletType.zcash) {
          height = await zcash!.getHeightByDate(date);
        } else if (widget.walletType == WalletType.zano) {
          height = zano!.getHeightByDate(date: date);
        } else {
          throw Exception("unknown currency in BlockchainHeightWidget");
        }
      }
      if (mounted) {
        setState(() {
          dateController.text = DateFormat('yyyy-MM-dd').format(date);
          restoreHeightController.text = '$height';
          _changeHeight(height);
        });
      }
    }
  }

  void _changeHeight(int height) {
    _height = height;
    widget.onHeightChange?.call(height);
  }
}
