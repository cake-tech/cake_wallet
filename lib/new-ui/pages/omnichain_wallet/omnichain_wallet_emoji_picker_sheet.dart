import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/select_background_color_widget.dart";
import "package:cw_core/card_design.dart";
import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/foundation.dart" as foundation;
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

// TODO(serhii): localize strings
const _titleText = "Select Icon";
const _doneText = "Done";
const _searchHintText = "Search Emoji";
const _noRecentsText = "No recents";
const _noResultsText = "No emoji found";

const _pickerHeight = 500.0;

class OmniChainWalletEmojiPickerSheet extends StatefulWidget {
  const OmniChainWalletEmojiPickerSheet({super.key, this.initial});

  final WalletIcon? initial;

  static List<Gradient> backgroundColors(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    return [
      LinearGradient(colors: [surface, surface]), // default (theme)
      ...CardDesign.allGradients,
    ];
  }

  static Future<WalletIcon?> show(BuildContext context, {WalletIcon? initial}) =>
      showCupertinoModalBottomSheet<WalletIcon>(
        context: context,
        barrierColor: Colors.black.withAlpha(85),
        builder: (_) => Material(
          child: OmniChainWalletEmojiPickerSheet(initial: initial),
        ),
      );

  @override
  State<OmniChainWalletEmojiPickerSheet> createState() => _OmniChainWalletEmojiPickerSheetState();
}

class _OmniChainWalletEmojiPickerSheetState extends State<OmniChainWalletEmojiPickerSheet> {
  static const _pickerRadius = Radius.circular(24);
  static const _previewSize = 100.0;

  late String _selectedEmoji;
  late int _selectedColorIndex;
  late bool _isBackgroundEnabled;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    _selectedEmoji = initial?.type == WalletIconType.emoji ? initial!.value : "";
    _selectedColorIndex = initial?.colorIndex ?? 0;
    _isBackgroundEnabled = initial?.backgroundEnabled ?? false;
  }

  void _onEmojiSelected(Category? category, Emoji emoji) =>
      setState(() => _selectedEmoji = emoji.emoji);

  void _onDone(int colorIndex) {
    if (_selectedEmoji.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop(
      WalletIcon(
        type: WalletIconType.emoji,
        value: _selectedEmoji,
        colorIndex: colorIndex,
        backgroundEnabled: _isBackgroundEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = OmniChainWalletEmojiPickerSheet.backgroundColors(context);
    final colorIndex = _selectedColorIndex.clamp(0, colors.length - 1);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTopBar(
            title: _titleText,
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).close,
            onLeadingPressed: () => Navigator.of(context).pop(),
            trailingIcon: const Icon(Icons.check),
            trailingSemanticLabel: _doneText,
            onTrailingPressed: () => _onDone(colorIndex),
          ),
          const SizedBox(height: 24),
          _EmojiPreview(
            emoji: _selectedEmoji,
            background: _isBackgroundEnabled ? colors[colorIndex] : null,
            size: _previewSize,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SelectBackgroundColorWidget(
              colors: colors,
              selectedIndex: colorIndex,
              onColorSelected: (index) => setState(() => _selectedColorIndex = index),
              isToggleable: true,
              isEnabled: _isBackgroundEnabled,
              onToggleChanged: (value) => setState(() => _isBackgroundEnabled = value),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: _pickerRadius),
            child: ColoredBox(
              color: _pickerBackground(scheme),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: _buildEmojiPicker(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker(ThemeData theme) {
    final scheme = theme.colorScheme;
    final background = _pickerBackground(scheme);
    final iconColor = scheme.onPrimary.withAlpha(150);
    final isIOS = foundation.defaultTargetPlatform == TargetPlatform.iOS;

    return EmojiPicker(
      onEmojiSelected: _onEmojiSelected,
      config: Config(
        height: _pickerHeight,
        checkPlatformCompatibility: true,
        viewOrderConfig: const ViewOrderConfig(
          top: EmojiPickerItem.searchBar,
          middle: EmojiPickerItem.emojiView,
          bottom: EmojiPickerItem.categoryBar,
        ),
        emojiViewConfig: EmojiViewConfig(
          columns: 8,
          emojiSizeMax: 28 * (isIOS ? 1.2 : 1.0),
          backgroundColor: background,
          noRecents: Text(
            _noRecentsText,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: iconColor),
          ),
        ),
        categoryViewConfig: CategoryViewConfig(
          initCategory: Category.SMILEYS,
          backgroundColor: background,
          indicatorColor: scheme.onPrimary,
          dividerColor: Colors.transparent,
          iconColor: iconColor,
          iconColorSelected: scheme.onPrimary,
        ),
        bottomActionBarConfig: BottomActionBarConfig(
          customBottomActionBar: (_, __, showSearchView) =>
              _EmojiSearchBarButton(onTap: showSearchView),
        ),
        searchViewConfig: const SearchViewConfig(
          customSearchView: _EmojiSearchView.new,
        ),
        skinToneConfig: SkinToneConfig(
          dialogBackgroundColor: scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

Color _pickerBackground(ColorScheme scheme) => scheme.primary;

class _EmojiPreview extends StatelessWidget {
  const _EmojiPreview({required this.emoji, required this.background, required this.size});

  final String emoji;
  final Gradient? background;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: background,
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.48)),
      );
}

class _EmojiSearchPill extends StatelessWidget {
  const _EmojiSearchPill({required this.leading, required this.child, this.onTap});

  final Widget leading;
  final Widget child;
  final VoidCallback? onTap;

  static const height = 50.0;
  static const outerPadding = EdgeInsets.fromLTRB(16, 16, 16, 8);

  static TextStyle? textStyle(ThemeData theme) =>
      theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary);

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                const SizedBox(width: 14),
                leading,
                const SizedBox(width: 8),
                Expanded(child: child),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      );
}

class _EmojiSearchBarButton extends StatelessWidget {
  const _EmojiSearchBarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      color: _pickerBackground(scheme),
      padding: _EmojiSearchPill.outerPadding,
      child: Semantics(
        button: true,
        label: _searchHintText,
        child: _EmojiSearchPill(
          onTap: onTap,
          leading: Icon(Icons.search, color: scheme.onPrimary),
          child: Text(_searchHintText, style: _EmojiSearchPill.textStyle(theme)),
        ),
      ),
    );
  }
}

class _EmojiSearchView extends SearchView {
  const _EmojiSearchView(super.config, super.state, super.showEmojiView);

  @override
  _EmojiSearchViewState createState() => _EmojiSearchViewState();
}

class _EmojiSearchViewState extends SearchViewState<_EmojiSearchView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = _EmojiSearchPill.textStyle(theme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - _EmojiSearchPill.outerPadding.horizontal;
        final emojiSize = widget.config.emojiViewConfig.getEmojiSize(gridWidth);
        final emojiBoxSize = widget.config.emojiViewConfig.getEmojiBoxSize(gridWidth);

        return Container(
          height: _pickerHeight,
          color: _pickerBackground(scheme),
          padding: _EmojiSearchPill.outerPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmojiSearchPill(
                leading: IconButton(
                  onPressed: widget.showEmojiView,
                  icon: Icon(Icons.close, color: scheme.onPrimary),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                child: TextField(
                  focusNode: focusNode,
                  onChanged: onTextInputChanged,
                  style: textStyle,
                  cursorColor: scheme.onPrimary,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _searchHintText,
                    hintStyle: textStyle?.copyWith(color: scheme.onPrimary.withAlpha(180)),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isCollapsed: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: emojiBoxSize * 4,
                // 4 visible rows, scrolls beyond; fits with the keyboard open
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          _noResultsText,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: scheme.onPrimary.withAlpha(150)),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widget.config.emojiViewConfig.columns,
                          mainAxisExtent: emojiBoxSize,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, i) =>
                            buildEmoji(results[i], emojiSize, emojiBoxSize),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
