import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/view_model/integrations/moonpay_virtual_account/moonpay_virtual_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class MoonPayVirtualAccountPage extends BasePage {
  MoonPayVirtualAccountPage({
    required this.viewModel,
    required this.details,
    this.transactions = const [],
  });

  final MoonPayVirtualAccountViewModel viewModel;
  final VirtualAccountDetailsDisplayData details;
  final List<VirtualAccountTransactionDisplayData> transactions;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
          (context, scaffold) => GradientBackground(scaffold: scaffold);

  @override
  String get title => '';

  @override
  Widget body(BuildContext context) {
    return _MoonPayVirtualAccountDetailsBody(
      details: details,
      transactions: transactions,
    );
  }
}

class VirtualAccountDetailsDisplayData {
  const VirtualAccountDetailsDisplayData({
    required this.fiatCurrencyCode, // usd | eur | gbp
    required this.payoutTokenCode, // usdc_sol | eurc_sol
    required this.accountHolderName,
    this.bankName,
    this.accountNumber,
    this.routingNumber,
    this.iban,
    this.swift,
    this.sortCode,
    this.reference,
    this.statusLabel,
  });

  final String fiatCurrencyCode;
  final String payoutTokenCode;
  final String accountHolderName;

  final String? bankName;
  final String? accountNumber;
  final String? routingNumber;
  final String? iban;
  final String? swift;
  final String? sortCode;
  final String? reference;
  final String? statusLabel;
}

class VirtualAccountTransactionDisplayData {
  const VirtualAccountTransactionDisplayData({
    required this.id,
    required this.status,
    required this.amountFiat,
    required this.fiatCurrencyCode,
    this.createdAtLabel,
    this.payoutAmountCrypto,
    this.payoutTokenCode,
  });

  final String id;
  final String status; // pending | completed | failed | refunded etc
  final String amountFiat;
  final String fiatCurrencyCode;

  final String? createdAtLabel;
  final String? payoutAmountCrypto;
  final String? payoutTokenCode;
}

class _MoonPayVirtualAccountDetailsBody extends StatelessWidget {
  const _MoonPayVirtualAccountDetailsBody({
    required this.details,
    required this.transactions,
  });

  final VirtualAccountDetailsDisplayData details;
  final List<VirtualAccountTransactionDisplayData> transactions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Virtual Account Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Use these bank details to transfer fiat into your virtual account.\nOnce funds settle, MoonPay will automatically ramp into your selected crypto.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 16),
            _DetailsHeaderCard(details: details),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SectionTitle('Bank details'),
                  const SizedBox(height: 10),
                  _DetailsCard(
                    children: [
                      _CopyFieldRow(
                        label: 'Account holder',
                        value: details.accountHolderName,
                      ),
                      if (details.bankName != null)
                        _CopyFieldRow(label: 'Bank', value: details.bankName!),
                      if (details.accountNumber != null)
                        _CopyFieldRow(
                          label: 'Account number',
                          value: details.accountNumber!,
                        ),
                      if (details.routingNumber != null)
                        _CopyFieldRow(
                          label: 'Routing number',
                          value: details.routingNumber!,
                        ),
                      if (details.sortCode != null)
                        _CopyFieldRow(label: 'Sort code', value: details.sortCode!),
                      if (details.iban != null)
                        _CopyFieldRow(label: 'IBAN', value: details.iban!),
                      if (details.swift != null)
                        _CopyFieldRow(label: 'SWIFT', value: details.swift!),
                      if (details.reference != null)
                        _CopyFieldRow(
                          label: 'Reference',
                          value: details.reference!,
                          helper:
                          'Include the reference so MoonPay can match your transfer.',
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('Pay in'),
                  const SizedBox(height: 10),
                  _DetailsCard(
                    children: [
                      _InfoLine(
                        title: 'Supported payment methods',
                        subtitle:
                        'ACH, Fedwire, SEPA Instant, Faster Payments (availability depends on region).',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _PillChip('ACH'),
                          _PillChip('Fedwire'),
                          _PillChip('SEPA Instant'),
                          _PillChip('Faster Payments'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoLine(
                        title: 'How it works',
                        subtitle:
                        'Transfer fiat to your virtual account. When funds settle, MoonPay (powered by Iron) automatically ramps into your selected crypto and sends it to your wallet.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('Autoramp'),
                  const SizedBox(height: 10),
                  _DetailsCard(
                    children: [
                      _InfoLine(
                        title: 'Automatic ramp',
                        subtitle:
                        'As fiat settles into your Virtual Account, MoonPay automatically converts it to ${_prettyToken(details.payoutTokenCode)} and sends it to your wallet.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('Transactions'),
                  const SizedBox(height: 10),
                  _TransactionsCard(transactions: transactions),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _prettyToken(String tokenCode) {
    // e.g. usdc_sol -> USDC (Solana)
    final parts = tokenCode.split('_');
    if (parts.length < 2) return tokenCode;
    final token = parts[0].toUpperCase();
    final network = parts[1];
    final networkLabel = network == 'sol' ? 'Solana' : network.toUpperCase();
    return '$token ($networkLabel)';
  }
}

class _DetailsHeaderCard extends StatelessWidget {
  const _DetailsHeaderCard({required this.details});

  final VirtualAccountDetailsDisplayData details;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              details.fiatCurrencyCode.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.92),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${details.fiatCurrencyCode.toUpperCase()} → ${details.payoutTokenCode.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details.statusLabel ?? 'Virtual account ready',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          const _PillChip('Copy all'),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.85),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: children
            .expand((w) => [w, const SizedBox(height: 10)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _CopyFieldRow extends StatelessWidget {
  const _CopyFieldRow({
    required this.label,
    required this.value,
    this.helper,
  });

  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (helper != null) ...[
                const SizedBox(height: 4),
                Text(
                  helper!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.copy,
              size: 18,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Colors.white.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.transactions});

  final List<VirtualAccountTransactionDisplayData> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No transactions yet. When you transfer fiat to this virtual account, the status will appear here.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            )
          else
            ...transactions
                .map((tx) => _TransactionRow(tx: tx))
                .expand((w) => [w, _ThinDivider()])
                .toList()
              ..removeLast(),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final VirtualAccountTransactionDisplayData tx;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              _statusIcon(tx.status),
              size: 22,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tx.amountFiat} ${tx.fiatCurrencyCode.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _StatusPill(tx.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tx.createdAtLabel ?? '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                if (tx.payoutAmountCrypto != null && tx.payoutTokenCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Autoramp: ${tx.payoutAmountCrypto} ${tx.payoutTokenCode!.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('complete') || s.contains('success')) return Icons.check;
    if (s.contains('fail') || s.contains('reject')) return Icons.close;
    if (s.contains('refund')) return Icons.undo;
    return Icons.hourglass_bottom;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.06),
    );
  }
}