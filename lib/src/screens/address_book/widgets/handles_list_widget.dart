import 'package:flutter/material.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/utils/image_utill.dart';

class HandlesListWidget extends StatefulWidget {
  const HandlesListWidget(
      {super.key,
      required this.items,
      this.initiallySelected = const [],
      this.onSelectionChanged});

  final List<AddressSource> items;

  final List<AddressSource> initiallySelected;

  final ValueChanged<Set<AddressSource>>? onSelectionChanged;

  @override
  State<HandlesListWidget> createState() => _HandlesListWidgetState();
}

class _HandlesListWidgetState extends State<HandlesListWidget> {
  late final Set<AddressSource> _selected = widget.initiallySelected.toSet();

  void _toggle(AddressSource src) {
    setState(() {
      if (_selected.contains(src)) {
        _selected.remove(src);
      } else {
        _selected.add(src);
      }
    });
    widget.onSelectionChanged?.call(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;

    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        final src = widget.items[i];
        final isSelected = _selected.contains(src);

        return ListTile(
          title: Text(src.label, style: theme.textTheme.bodyMedium),
          trailing: Text(src.alias, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),),
          tileColor: theme.colorScheme.surfaceContainer,
          splashColor: Colors.transparent,
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: isSelected
                    ? Icon(Icons.check_circle, size: 20, color: iconColor)
                    : Icon(Icons.circle_outlined, size: 20, color: iconColor),
              ),
              const SizedBox(width: 6),
              ImageUtil.getImageFromPath(
                imagePath: src.iconPath,
                height: 24,
                width: 24,
              ),
            ],
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          onTap: () => _toggle(src),
        );
      },
    );
  }
}
