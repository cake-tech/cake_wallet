import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_simple_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PickerItem<Item> {
  final String title;
  final String? subtitle;
  final String? hint;
  final Item value;
  final bool isSliderItem;

  PickerItem(
      {required this.title,
      this.subtitle,
      this.hint,
      required this.value,
      this.isSliderItem = false});
}

class NewPicker<Item> extends StatefulWidget {
  const NewPicker({
    super.key,
    this.title = "Please select",
    this.sliderPageTitle = "Custom value",
    required this.items,
    this.description,
    required this.onItemSelected,
    this.sliderInitialValue,
    this.sliderMaxValue,
    this.sliderValueDescription,
    this.onSliderChanged,
    required this.selectedIndex,
    this.closeOnSelection = false,
  });

  final String title;
  final String sliderPageTitle;
  final String? description;
  final String? sliderValueDescription;
  final List<PickerItem<Item>> items;
  final int selectedIndex;
  final Function(Item) onItemSelected;
  final double? sliderInitialValue;
  final double? sliderMaxValue;
  final Function(double)? onSliderChanged;
  final bool closeOnSelection;

  @override
  State<NewPicker<Item>> createState() => _NewPickerState();
}

class _NewPickerState<Item> extends State<NewPicker<Item>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTopBar(
            title: widget.title,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).maybePop,
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.description != null && widget.description!.isNotEmpty)
                  Text(widget.description!),
                ...widget.items.map((item) {
                  return Column(children: [
                    if (item.isSliderItem)
                      PickerSliderButton(
                        item: item,
                        isSelected: widget.items.indexOf(item) == item,
                        onSelected: (item) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => PickerSliderPage(
                                  title: widget.sliderPageTitle,
                                  sliderInitialValue: widget.sliderInitialValue!,
                                  valueDescription: widget.sliderValueDescription ?? "",
                                  sliderMaxValue: widget.sliderMaxValue!,
                                  onSubmitted: (value) {
                                    widget.onSliderChanged?.call(value);
                                  })));
                        },
                        isFirst: widget.items.indexOf(item) == 0,
                        isLast: widget.items.indexOf(item) == widget.items.length - 1,
                      )
                    else
                      PickerRow(
                        item: item,
                        isSelected: widget.items.indexOf(item) == widget.selectedIndex,
                        onSelected: _itemSelected,
                        isFirst: widget.items.indexOf(item) == 0,
                        isLast: widget.items.indexOf(item) == widget.items.length - 1,
                      ),
                    if (widget.items.indexOf(item) != widget.items.length - 1)
                      Container(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Container(
                            height: 1,
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          ),
                        ),
                      )
                  ]);
                })
              ],
            ),
          )
        ],
      ),
    );
  }

  void _itemSelected(Item value) {
    widget.onItemSelected(value);
    if (widget.closeOnSelection) {
      Navigator.of(context).pop();
    }
  }
}

class PickerSliderButton<Item> extends StatelessWidget {
  const PickerSliderButton(
      {super.key,
      required this.item,
      required this.isSelected,
      required this.onSelected,
      required this.isFirst,
      required this.isLast});

  final PickerItem<Item> item;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final Function(Item) onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelected(item.value);
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(
                top: isFirst ? Radius.circular(16) : Radius.circular(0),
                bottom: isLast ? Radius.circular(16) : Radius.circular(0))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500),
                      ),
                      if (item.hint != null)
                        Text(item.hint!,
                            style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400))
                    ],
                  ),
                  if (item.subtitle != null) Text(item.subtitle!)
                ],
              ),
              SvgPicture.asset(
                "assets/new-ui/arrow_right.svg",
                colorFilter:
                    ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PickerRow<Item> extends StatelessWidget {
  const PickerRow(
      {super.key,
      required this.item,
      required this.isSelected,
      required this.onSelected,
      required this.isFirst,
      required this.isLast});

  final PickerItem<Item> item;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final Function(Item) onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelected(item.value);
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(
                top: isFirst ? Radius.circular(16) : Radius.circular(0),
                bottom: isLast ? Radius.circular(16) : Radius.circular(0))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    spacing: 4,
                    children: [
                      Text(item.title,
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500)),
                      if (item.hint != null)
                        Text(item.hint!,
                            style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400))
                    ],
                  ),
                  item.subtitle != null ? Text(item.subtitle!) : SizedBox.shrink()
                ],
              ),
              NewSimpleCheckbox(
                  value: isSelected,
                  onChanged: (value) {
                    onSelected(item.value);
                  })
            ],
          ),
        ),
      ),
    );
  }
}

class PickerSliderPage<Item> extends StatefulWidget {
  const PickerSliderPage(
      {super.key,
      required this.sliderInitialValue,
      required this.sliderMaxValue,
      required this.onSubmitted,
      required this.title,
      this.valueDescription = ""});

  final double sliderInitialValue;
  final double sliderMaxValue;
  final Function(double) onSubmitted;
  final String title;
  final String valueDescription;

  @override
  State<PickerSliderPage<Item>> createState() => _PickerSliderPageState();
}

class _PickerSliderPageState<Item> extends State<PickerSliderPage<Item>> {
  late double sliderValue;

  @override
  void initState() {
    super.initState();
    sliderValue = widget.sliderInitialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            ModalTopBar(
              title: widget.title,
              leadingIcon: Icon(Icons.arrow_back_ios_new),
              onLeadingPressed: Navigator.of(context).pop,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(mainAxisAlignment:MainAxisAlignment.center,spacing:4,children: [
                    Text(sliderValue.toStringAsFixed(0), style: TextStyle(fontSize:18,fontWeight: FontWeight.w600,color: Theme.of(context).colorScheme.primary),),
                    Text(widget.valueDescription, style: TextStyle(fontSize:18,fontWeight: FontWeight.w600,color: Theme.of(context).colorScheme.onSurface)),
                  ],),
                  Slider(
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).colorScheme.surfaceContainer,
                    thumbColor: Theme.of(context).colorScheme.onSurface,
                    value: sliderValue,
                    onChanged: (value) {
                      setState(() {
                        sliderValue = value.roundToDouble();
                      });
                    },
                    min: 1,
                    max: widget.sliderMaxValue,
                  ),
                ],
              ),
            ),
            NewPrimaryButton(onPressed: (){
              widget.onSubmitted(sliderValue);
              Navigator.of(context).pop();
            }, text: "Continue", color: Theme.of(context).colorScheme.primary, textColor: Theme.of(context).colorScheme.onPrimary)
          ],
        ),
      ),
    );
  }
}
