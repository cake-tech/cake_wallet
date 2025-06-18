import 'package:cake_wallet/core/seed_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/validable_annotated_editable_text.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeedWidget extends StatefulWidget {
  SeedWidget({
    required this.language,
    required this.type,
    this.onSeedChange,
    this.pasteButtonKey,
    this.seedTextFieldKey,
    this.initialSeed,
    super.key,
  });
  final Key? seedTextFieldKey;
  final Key? pasteButtonKey;
  final String language;
  final WalletType type;
  final void Function(String)? onSeedChange;
  final String? initialSeed;

  @override
  SeedWidgetState createState() => SeedWidgetState(language, type, initialSeed);
}

class SeedWidgetState extends State<SeedWidget> {
  SeedWidgetState(String language, this.type, String? initialSeed)
      : controller = TextEditingController(text: initialSeed ?? ''),
        focusNode = FocusNode(),
        words = SeedValidator.getWordList(type: type, language: language),
        _showPlaceholder = initialSeed == null || initialSeed.isEmpty {
    focusNode.addListener(() {
      setState(() {
        if (!focusNode.hasFocus && controller.text.isEmpty) {
          _showPlaceholder = true;
        }

        if (focusNode.hasFocus) {
          _showPlaceholder = false;
        }
      });
    });
  }

  final TextEditingController controller;
  final FocusNode focusNode;
  final WalletType type;
  List<String> words;
  bool normalizeSeed = false;
  bool _showPlaceholder;

  String get text => controller.text;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        _showPlaceholder = controller.text.isEmpty;
      });
      widget.onSeedChange?.call(text);
    });
    Future.delayed(Duration.zero, () {
      widget.onSeedChange?.call(text);
    });
  }

  void changeSeedLanguage(String language) {
    setState(() {
      words = SeedValidator.getWordList(type: type, language: language);
      normalizeSeed = SeedValidator.needsNormalization(language);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 12, right: 8, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              constraints: BoxConstraints(minHeight: 40),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ValidatableAnnotatedEditableText(
                                  key: widget.seedTextFieldKey,
                                  cursorColor: Theme.of(context).colorScheme.primary,
                                  backgroundCursorColor: Theme.of(context).colorScheme.primary,
                                  validStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    backgroundColor: Colors.transparent,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                  invalidStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        color: Theme.of(context).colorScheme.errorContainer,
                                        backgroundColor: Colors.transparent,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                  focusNode: focusNode,
                                  controller: controller,
                                  words: words,
                                  normalizeSeed: normalizeSeed,
                                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        backgroundColor: Colors.transparent,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                ),
                              ),
                            ),
                            if (_showPlaceholder)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      S.of(context).enter_seed_phrase,
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 16,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        child: InkWell(
                          key: widget.pasteButtonKey,
                          onTap: () async => _pasteText(),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/paste_ios.png',
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteText() async {
    final value = (await Clipboard.getData('text/plain'))?.text?.trim();

    if (value?.isNotEmpty ?? false) {
      setState(() {
        _showPlaceholder = false;
        controller.text = value!;
      });
    }
  }
}
