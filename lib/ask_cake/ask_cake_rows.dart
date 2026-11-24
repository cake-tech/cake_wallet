import 'package:flutter/material.dart';

/// One transaction or swap from a wallet answer, ready to draw as a row.
class AskCakeRow {
  const AskCakeRow.transaction({
    required this.date,
    required this.incoming,
    required this.amount,
    this.fiat,
    this.note,
    this.pending = false,
  })  : isSwap = false,
        provider = null,
        status = null,
        swapId = null;

  const AskCakeRow.swap({
    required this.date,
    required this.amount,
    required this.provider,
    required this.status,
    required this.swapId,
  })  : isSwap = true,
        incoming = false,
        fiat = null,
        note = null,
        pending = false;

  final bool isSwap;
  final String date;
  final bool incoming;

  /// "0.125 LTC" for a transaction, "0.62 XMR → 1.1 LTC" for a swap.
  final String amount;
  final String? fiat;
  final String? note;
  final bool pending;
  final String? provider;
  final String? status;
  final String? swapId;
}

/// One figure from a wallet answer: "Available balance" / "1.2 LTC" / "USD 90.00".
class AskCakeFact {
  const AskCakeFact(this.label, this.value, this.detail);

  final String label;
  final String value;

  /// Secondary figures the wallet wrote after the value (fiat worth, a count, a note).
  final String? detail;

  static final _line = RegExp(r'^(?:- )?([A-Z][^:\n]{1,48}): (\S.*)$');

  static AskCakeFact? parse(String line) {
    final match = _line.firstMatch(line);
    if (match == null) return null;
    var value = match.group(2)!.trim();
    if (value.endsWith('.')) value = value.substring(0, value.length - 1);
    // "0.5 LTC (USD 40.00) in 3 transactions": the first bracket and what follows are detail.
    final split = RegExp(r'^(.+?) \((.+)$').firstMatch(value);
    // A list of bracketed names ("Savings (Monero), Daily (Bitcoin)") is one value, not a value and its detail.
    if (split == null || split.group(1)!.contains(',') || value.contains('), ')) {
      return AskCakeFact(match.group(1)!, value, null);
    }
    final detail = split
        .group(2)!
        .split(RegExp(r'\)\s*\(?|\s\('))
        .map((part) => part.replaceAll(RegExp(r'^[\s(]+|[\s)]+$'), '').replaceFirst(RegExp(r'^in (?=\d)'), ''))
        .where((part) => part.isNotEmpty)
        .join(' · ');
    return AskCakeFact(match.group(1)!, split.group(1)!, detail.isEmpty ? null : detail);
  }
}

/// A stretch of a reply: plain text, a list of rows, a card of figures, or small print under a list.
class AskCakeBlock {
  const AskCakeBlock.text(this.text)
      : rows = const [],
        facts = const [],
        small = false;
  const AskCakeBlock.rows(this.rows)
      : text = '',
        facts = const [],
        small = false;
  const AskCakeBlock.facts(this.facts)
      : text = '',
        rows = const [],
        small = false;
  const AskCakeBlock.small(this.text)
      : rows = const [],
        facts = const [],
        small = true;

  final String text;
  final List<AskCakeRow> rows;
  final List<AskCakeFact> facts;
  final bool small;

  static final _transaction = RegExp(
      r'^- (\d{4}-\d{2}-\d{2}) (sent|received) (.+?)(?: \(([^)]*)\))?(?:,? fee [^,]+)?(, pending)?(?:,? note: (.*))?$');
  static final _swap =
      RegExp(r'^- (\d{4}-\d{2}-\d{2}) (\S+ \S+) -> (\S+ \S+) via (.+?) \(([^)]*)\) swap ID: (\S+)$');

  static AskCakeRow? _row(String line) {
    final swap = _swap.firstMatch(line);
    if (swap != null) {
      return AskCakeRow.swap(
        date: swap.group(1)!,
        amount: '${swap.group(2)} → ${swap.group(3)}',
        provider: swap.group(4),
        status: swap.group(5),
        swapId: swap.group(6),
      );
    }
    final tx = _transaction.firstMatch(line);
    if (tx != null) {
      final note = tx.group(6)?.trim();
      return AskCakeRow.transaction(
        date: tx.group(1)!,
        incoming: tx.group(2) == 'received',
        amount: tx.group(3)!.trim(),
        fiat: tx.group(4),
        note: note == null || note.isEmpty ? null : note,
        pending: tx.group(5) != null,
      );
    }
    return null;
  }

  /// Splits a reply into text, lists and figures. The words are unchanged:
  /// lines the wallet tools wrote as "- date sent ..." or "- date A -> B via ..."
  /// are lifted out as rows, "Label: value" lines become a card of figures, and
  /// the totals that follow a swap list become small print. Only the stretch
  /// from [dataStart] to [dataEnd] (what the wallet tools wrote) is laid out
  /// this way; sentences around it stay as written.
  static List<AskCakeBlock> parse(String reply, {int? dataStart, int? dataEnd}) {
    if (dataStart == null || dataEnd == null || dataStart < 0 || dataEnd > reply.length || dataStart >= dataEnd) {
      return _parse(reply, figures: false);
    }
    final before = reply.substring(0, dataStart).trim();
    final after = reply.substring(dataEnd).trim();
    return [
      if (before.isNotEmpty) AskCakeBlock.text(before),
      ..._parse(reply.substring(dataStart, dataEnd), figures: true),
      if (after.isNotEmpty) AskCakeBlock.text(after),
    ];
  }

  static List<AskCakeBlock> _parse(String reply, {required bool figures}) {
    final blocks = <AskCakeBlock>[];
    final text = <String>[];
    final rows = <AskCakeRow>[];
    final facts = <AskCakeFact>[];
    var afterRows = false;
    void flushText({bool small = false}) {
      final joined = text.join('\n').trim();
      if (joined.isNotEmpty) blocks.add(small ? AskCakeBlock.small(joined) : AskCakeBlock.text(joined));
      text.clear();
    }

    void flushRows() {
      if (rows.isNotEmpty) blocks.add(AskCakeBlock.rows(List.of(rows)));
      rows.clear();
    }

    void flushFacts() {
      if (facts.isNotEmpty) blocks.add(AskCakeBlock.facts(List.of(facts)));
      facts.clear();
    }

    for (final line in reply.split('\n')) {
      final row = line.startsWith('- ') ? _row(line) : null;
      if (row != null) {
        flushFacts();
        if (rows.isEmpty) flushText(small: afterRows);
        rows.add(row);
        continue;
      }
      if (rows.isNotEmpty) {
        flushRows();
        afterRows = true;
      }
      final fact = figures && !afterRows ? AskCakeFact.parse(line) : null;
      if (fact != null) {
        flushText();
        facts.add(fact);
        continue;
      }
      flushFacts();
      if (afterRows && line.trim().isEmpty && text.isNotEmpty) {
        // A blank line ends the small print (what follows is a new paragraph, e.g. the support note).
        flushText(small: true);
        afterRows = false;
        continue;
      }
      // The failed swaps are already in the list, marked failed: keep the count, drop the repeat.
      final failed = RegExp(r'^(Failed swaps: \d+)').firstMatch(line);
      text.add(failed != null && afterRows ? failed.group(1)! : line);
    }
    flushRows();
    flushFacts();
    flushText(small: afterRows);
    return blocks;
  }
}

/// Figures from the wallet, drawn as a card: the name on the left, the value on
/// the right, with long values given their own line.
class AskCakeFactsCard extends StatelessWidget {
  const AskCakeFactsCard({super.key, required this.facts});

  final List<AskCakeFact> facts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = TextStyle(fontSize: 13.5, height: 1.25, color: colors.onSurfaceVariant);
    final value = TextStyle(fontSize: 15, height: 1.25, fontWeight: FontWeight.w600, color: colors.onSurface);
    final detail = TextStyle(fontSize: 12.5, height: 1.3, color: colors.onSurfaceVariant);
    Widget row(AskCakeFact fact) {
      final long = fact.value.length > 22 || fact.label.length > 26;
      return Semantics(
        container: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: long
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fact.label, style: label),
                    const SizedBox(height: 3),
                    SelectableText(fact.value, style: value.copyWith(fontSize: 14.5)),
                    if (fact.detail != null) Text(fact.detail!, style: detail),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 1), child: Text(fact.label, style: label)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fact.value, textAlign: TextAlign.end, style: value),
                          if (fact.detail != null) Text(fact.detail!, textAlign: TextAlign.end, style: detail),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.88,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 14, endIndent: 14, color: colors.outlineVariant.withValues(alpha: 0.5)),
            row(facts[i]),
          ],
        ],
      ),
    );
  }
}

/// A list of transactions or swaps, drawn as a card of rows.
class AskCakeRowsCard extends StatelessWidget {
  const AskCakeRowsCard({super.key, required this.rows});

  final List<AskCakeRow> rows;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String _date(String iso) {
    final parts = iso.split('-');
    final month = int.tryParse(parts[1]) ?? 1;
    return '${int.tryParse(parts[2]) ?? parts[2]} ${_months[(month - 1).clamp(0, 11)]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 58, color: colors.outlineVariant.withValues(alpha: 0.5)),
            _row(context, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AskCakeRow row) {
    final colors = Theme.of(context).colorScheme;
    final failed = row.isSwap && !_done.contains(row.status?.toLowerCase());
    final Color accent = row.isSwap
        ? (failed ? colors.error : colors.primary)
        : row.incoming
            ? const Color(0xFF34C77B)
            : colors.primary;
    final title = row.isSwap ? row.amount : (row.note ?? (row.incoming ? 'Received' : 'Sent'));
    final subtitle = [
      _date(row.date),
      if (row.isSwap && row.provider != null) row.provider!,
      if (row.pending) 'pending',
    ].join(' · ');
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(
                row.isSwap
                    ? Icons.swap_horiz_rounded
                    : row.incoming
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant)),
                  if (row.isSwap && row.swapId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SelectableText('ID ${row.swapId}',
                          style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant, fontFamily: 'monospace')),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (row.isSwap)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                child: Text(row.status ?? '',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: accent)),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${row.incoming ? '+' : '−'}${row.amount}',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: row.incoming ? const Color(0xFF34C77B) : colors.onSurface)),
                  if (row.fiat != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(row.fiat!, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static const _done = {'complete', 'completed', 'finished', 'traded', 'settled', 'success'};
}

/// Three dots that rise and fall in turn while a reply is being worked out.
class AskCakeThinking extends StatefulWidget {
  const AskCakeThinking({super.key});

  @override
  State<AskCakeThinking> createState() => _AskCakeThinkingState();
}

class _AskCakeThinkingState extends State<AskCakeThinking> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final still = MediaQuery.of(context).disableAnimations;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: 'Thinking',
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(18)),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Builder(builder: (context) {
                    // Each dot takes its turn in the first half of its own cycle.
                    final phase = still ? 0.0 : ((_controller.value - i * 0.16) % 1.0);
                    final lift = phase < 0.5 ? Curves.easeInOut.transform(1 - (phase * 4 - 1).abs().clamp(0.0, 1.0)) : 0.0;
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      child: Transform.translate(
                        offset: Offset(0, -5 * lift),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(colors.onSurfaceVariant.withValues(alpha: 0.45), colors.primary, lift),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
