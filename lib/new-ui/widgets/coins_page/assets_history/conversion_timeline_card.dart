import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/entities/conversion_display.dart";
import "package:cake_wallet/entities/conversion_status.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

/// The payment detail page's conversion timeline ("Variant C" of the Stable Balance mockups):
/// payment received, then the conversion step, then - once the SDK reports them - what went in,
/// what came out, and any amount adjustment.
class ConversionTimelineCard extends StatelessWidget {
  const ConversionTimelineCard({
    super.key,
    required this.display,
    required this.paymentReceivedAt,
    this.onRequestRefund,
    this.refunding = false,
  });

  final ConversionDisplay display;
  final DateTime paymentReceivedAt;

  /// Null hides the button entirely - only meaningful while a refund is actually available
  /// (see `TransactionDetailsViewModelBase.canRequestConversionRefund`).
  final VoidCallback? onRequestRefund;

  /// A refund request is in flight - the button shows progress and ignores taps.
  final bool refunding;

  static const _doneColor = Color(0xFF1F9D55);
  static const _pendingColor = Color(0xFFB26A00);
  static const _failureColor = Color(0xFFC93A3A);

  bool get _isFailure => ConversionDisplayUtils.needsAttention(display.status);

  String? _adjustmentText(BuildContext context) => switch (display.amountAdjustment) {
        ConversionAmountAdjustment.flooredToMinLimit =>
          S.of(context).conversion_adjustment_min_limit,
        ConversionAmountAdjustment.increasedToAvoidDust =>
          S.of(context).conversion_adjustment_avoid_dust,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final fees = [display.fromFee, display.toFee].whereType<String>().join(" + ");
    final adjustment = _adjustmentText(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).conversion_status_title,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          _step(
            context,
            icon: Icons.check,
            label: S.of(context).conversion_payment_received,
            sublabel: DateFormat.jm().format(paymentReceivedAt),
            color: _doneColor,
            filled: true,
          ),
          _connector(context),
          if (_isFailure)
            _step(
              context,
              icon: Icons.warning_amber_rounded,
              label: S.of(context).conversion_failed,
              sublabel: display.status == ConversionStatus.refundNeeded
                  ? S.of(context).conversion_failed_refund_hint(display.fromTicker)
                  : S.of(context).conversion_failed_not_lost(display.fromTicker),
              color: _failureColor,
            )
          else if (display.status == ConversionStatus.pending)
            _step(
              context,
              icon: Icons.schedule,
              label: S.of(context).conversion_converting_to(display.toLabel),
              sublabel: S.of(context).conversion_usually_seconds,
              color: _pendingColor,
            )
          else
            _step(
              context,
              icon: Icons.check,
              label: display.status == ConversionStatus.refunded
                  ? S.of(context).conversion_refunded
                  : S.of(context).conversion_converted_from(display.fromLabel),
              color: _doneColor,
              filled: true,
            ),
          if (display.fromAmount != null && display.toAmount != null) ...[
            const SizedBox(height: 16),
            _detailRow(context, S.of(context).from, display.fromAmount!),
            _detailRow(context, S.of(context).to, display.toAmount!),
            if (fees.isNotEmpty) _detailRow(context, S.of(context).transaction_details_fee, fees),
          ],
          if (adjustment != null) ...[
            const SizedBox(height: 8),
            Text(
              adjustment,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (onRequestRefund != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey("conversion_request_refund_button"),
                onPressed: refunding ? null : onRequestRefund,
                style: FilledButton.styleFrom(
                  backgroundColor: _failureColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: refunding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        S.of(context).request_refund,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _connector(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 11),
        child: Container(
          width: 2,
          height: 16,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );

  Widget _detailRow(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _step(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    String? sublabel,
    bool filled = false,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: filled ? color : color.withAlpha(35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: filled ? Colors.white : color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: filled ? Theme.of(context).colorScheme.onSurface : color,
                  ),
                ),
                if (sublabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}
