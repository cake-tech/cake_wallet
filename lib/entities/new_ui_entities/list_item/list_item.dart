import 'package:flutter/material.dart';

abstract class ListItem {
  const ListItem({
    required this.keyValue,
    required this.label,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;

  final bool isFirstInSection;
  final bool isLastInSection;

  BorderRadius get radius => BorderRadius.vertical(
    top: Radius.circular(isFirstInSection ? 16 : 0),
    bottom: Radius.circular(isLastInSection ? 16 : 0),
  );
}

// class NewListRow extends StatefulWidget {
//   NewListRow({
//     required this.key,
//     this.controller,
//     required this.label,
//     this.subtitle,
//     this.trailingText,
//     this.initialValue,
//     this.isFirstInSection = false,
//     this.isLastInSection = false,
//     this.checkboxValue = false,
//     this.onCheckboxChanged,
//     this.onRowTapped,
//     this.validator,
//   });
//
//   final NewListRowType type;
//   final ValueKey<String> key;
//   final TextEditingController? controller;
//   final String label;
//   final String? subtitle;
//   final String? trailingText;
//   final String? initialValue;
//   final bool isFirstInSection;
//   final bool isLastInSection;
//   final bool checkboxValue;
//   final ValueChanged<bool>? onCheckboxChanged;
//   final VoidCallback? onRowTapped;
//   final FormFieldValidator<String>? validator;
//
//   @override
//   State<NewListRow> createState() =>
//       _NewListRowState(checkboxValue: checkboxValue);
// }

// class _NewListRowState extends State<NewListRow> {
//   _NewListRowState({required this.checkboxValue});
//
//   bool checkboxValue;
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final backgroundColor = theme.colorScheme.surfaceContainer;
//     final borderSide =
//         BorderSide(color: theme.colorScheme.surfaceContainerHigh, width: 1);
//     final borderRadius = BorderRadius.vertical(
//       top: Radius.circular(widget.isFirstInSection ? 16.0 : 0.0),
//       bottom: Radius.circular(widget.isLastInSection ? 16.0 : 0.0),
//     );
//     final underlineInputBorder = widget.isLastInSection
//         ? InputBorder.none
//         : UnderlineInputBorder(borderSide: borderSide);
//     final TextStyle _textStyle = TextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.w400,
//       fontFamily: 'Wix Madefor Text',
//       color: theme.colorScheme.onSurface,
//     );
//     final TextStyle _labelStyle = TextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.w500,
//       fontFamily: 'Wix Madefor Text',
//       color: theme.colorScheme.onSurfaceVariant,
//     );
//
//
//     Widget _buildTextFormField() {
//       return TextFormField(
//         key: widget.key,
//         controller: widget.controller,
//         style: _textStyle,
//         validator: widget.validator,
//         decoration: InputDecoration(
//           fillColor: backgroundColor,
//           labelText: widget.label,
//           labelStyle: _labelStyle,
//           border: underlineInputBorder,
//           focusedBorder: underlineInputBorder,
//           enabledBorder: underlineInputBorder,
//           disabledBorder: underlineInputBorder,
//           isDense: true,
//           contentPadding: EdgeInsets.symmetric(vertical: 7.0),
//         ),
//       );
//     }
//
//     Widget _buildCheckboxRow() {
//       return Container(
//         height: 48,
//         decoration: BoxDecoration(
//           border: widget.isLastInSection ? null : Border(bottom: borderSide),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(widget.label, style: _textStyle),
//             NewStandardRoundCheckbox(
//               value: checkboxValue,
//               onChanged: (bool newValue) {
//                 setState(() => checkboxValue = newValue);
//                 widget.onCheckboxChanged?.call(newValue);
//               },
//             ),
//           ],
//         ),
//       );
//     }
//
//     Widget _buildToggleRow() {
//       return Container(
//         height: 48,
//         decoration: BoxDecoration(
//           border: widget.isLastInSection ? null : Border(bottom: borderSide),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(widget.label, style: _textStyle),
//             StandardSwitch(
//               value: checkboxValue,
//               onTapped: () {
//                 final newValue = !checkboxValue;
//                 setState(() => checkboxValue = newValue);
//                 widget.onCheckboxChanged?.call(newValue);
//               },
//             ),
//           ],
//         ),
//       );
//     }
//
//     Widget _buildRegularWithTrailingRow() {
//       return GestureDetector(
//         onTap: () {
//           _showToast('Tapped on ${widget.label} row');
//         },
//         child: Container(
//           height: widget.subtitle != null ? 60 : 48,
//           decoration: BoxDecoration(
//             border: widget.isLastInSection ? null : Border(bottom: borderSide),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(widget.label, style: _textStyle),
//                   if (widget.subtitle != null)
//                     Text(
//                       widget.subtitle!,
//                       style: _labelStyle,
//                     ),
//
//                 ],
//
//               ),
//               Row(
//                 children: [
//                   if (widget.trailingText != null)
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8.0),
//                       child: Text(
//                         widget.trailingText!,
//                         style: _labelStyle,
//                       ),
//                     ),
//                   Icon(
//                     Icons.chevron_right,
//                     color: theme.colorScheme.onSurfaceVariant,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     Widget _buildItemSelectorRow() {
//       return GestureDetector(
//         onTap: () {
//           _showToast('Tapped on ${widget.label} row');
//         },
//         child: Container(
//           height: 48,
//           decoration: BoxDecoration(
//             border: widget.isLastInSection ? null : Border(bottom: borderSide),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(widget.label, style: _textStyle),
//               Row(
//                 children: [
//                   if (widget.trailingText != null)
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8.0),
//                       child: Text(
//                         widget.trailingText!,
//                         style: _labelStyle,
//                       ),
//                     ),
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.keyboard_arrow_up_outlined,
//                         color: theme.colorScheme.onSurfaceVariant,
//                         size: 16,
//                       ),
//                       Icon(
//                         Icons.keyboard_arrow_down_outlined,
//                         color: theme.colorScheme.onSurfaceVariant,
//                         size: 16,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     Widget _buildDropdownRow() {
//       return GestureDetector(
//         onTap: () {
//           _showToast('Tapped on ${widget.label} row');
//         },
//         child: Container(
//           height: 48,
//           decoration: BoxDecoration(
//             border: widget.isLastInSection ? null : Border(bottom: borderSide),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(widget.label, style: _textStyle),
//               Row(
//                 children: [
//                   if (widget.trailingText != null)
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8.0),
//                       child: Text(
//                         widget.trailingText!,
//                         style: _labelStyle,
//                       ),
//                     ),
//                   Icon(
//                     Icons.arrow_drop_down,
//                     color: theme.colorScheme.onSurfaceVariant,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     Widget _buildByType() {
//       switch (widget.type) {
//         case NewListRowType.textFormField:
//           return _buildTextFormField();
//
//         case NewListRowType.checkbox:
//           return _buildCheckboxRow();
//
//         case NewListRowType.toggle:
//           return _buildToggleRow();
//
//         case NewListRowType.regularWithTrailing:
//           return _buildRegularWithTrailingRow();
//
//         case NewListRowType.itemSelector:
//           return _buildItemSelectorRow();
//
//         case NewListRowType.dropdown:
//           return _buildDropdownRow();
//
//         default:
//           return const SizedBox.shrink();
//       }
//     }
//
//     return Row(
//       children: [
//         Expanded(
//           child: ClipRRect(
//             borderRadius: borderRadius,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: backgroundColor,
//                 borderRadius: borderRadius,
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                 child: _buildByType(),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _showToast(String msg) async {
//     try {
//       await Fluttertoast.showToast(
//         msg: msg,
//         backgroundColor: Color.fromRGBO(0, 0, 0, 0.85),
//       );
//     } catch (_) {}
//   }
// }
//
// class NewStandardRoundCheckbox extends StatelessWidget {
//   const NewStandardRoundCheckbox({
//     super.key,
//     required this.value,
//     required this.onChanged,
//   });
//
//   final bool value;
//   final ValueChanged<bool> onChanged;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         onChanged(!value);
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: value
//               ? Theme.of(context).colorScheme.primary
//               : Theme.of(context).colorScheme.surfaceContainerHighest,
//           borderRadius: const BorderRadius.all(Radius.circular(50)),
//         ),
//         height: 24,
//         width: 24,
//         child: value
//             ? Icon(
//                 Icons.check,
//                 color: Theme.of(context).colorScheme.onPrimary,
//                 size: 20,
//               )
//             : const SizedBox.shrink(),
//       ),
//     );
//   }
// }
