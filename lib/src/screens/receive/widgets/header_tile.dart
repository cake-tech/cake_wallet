import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';

class HeaderTile extends StatefulWidget {
  HeaderTile({
    required this.title,
    required this.walletAddressListViewModel,
    this.showSearchButton = false,
    this.showTrailingButton = false,
    this.trailingButtonTap,
    this.onSearchCallback,
    this.trailingIcon,
  });

  final String title;
  final WalletAddressListViewModel walletAddressListViewModel;
  final bool showSearchButton;
  final bool showTrailingButton;
  final VoidCallback? trailingButtonTap;
  final VoidCallback? onSearchCallback;
  final Icon? trailingIcon;

  @override
  _HeaderTileState createState() => _HeaderTileState();
}

class _HeaderTileState extends State<HeaderTile> {
  bool _isSearchActive = false;

  @override
  Widget build(BuildContext context) {
    final searchIcon = Icon(Icons.search, color: Theme.of(context).colorScheme.primary);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _isSearchActive
              ? Expanded(
                  child: BaseTextFormField(
                    onChanged: (value) {
                      widget.walletAddressListViewModel.updateSearchText(value);
                      widget.onSearchCallback?.call();
                    },
                    cursorColor: Theme.of(context).colorScheme.onSurface,
                    cursorWidth: 0.5,
                    isDense: true,
                    hintText: '${S.of(context).search}...',
                    contentPadding: EdgeInsets.all(4),
                    placeholderTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                    autofocus: true,
                  ),
                )
              : Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
          Row(
            children: [
              if (widget.showSearchButton)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchActive = !_isSearchActive;
                      widget.walletAddressListViewModel.updateSearchText('');
                    });
                  },
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    child: searchIcon,
                  ),
                ),
              const SizedBox(width: 8),
              if (widget.showTrailingButton)
                GestureDetector(
                  onTap: widget.trailingButtonTap,
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    child: widget.trailingIcon,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
