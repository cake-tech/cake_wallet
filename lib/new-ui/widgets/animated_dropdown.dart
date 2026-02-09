import 'package:cake_wallet/new-ui/widgets/dropdown_row.dart';
import 'package:flutter/material.dart';

class AnimatedDropdown extends StatefulWidget {
  const AnimatedDropdown({super.key,required this.content, required this.dropdownText});

  final Widget content;
  final String dropdownText;

  @override
  State<AnimatedDropdown> createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<AnimatedDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(20),
          ),
            color: Theme.of(context).colorScheme.surfaceContainer,),
        child: Column(
          children: [
            DropdownRow(expanded: _expanded, text: widget.dropdownText,onTap: (){
              setState(() {
                _expanded = !_expanded;
              });
            },),
   AnimatedOpacity(duration:Duration(milliseconds: 150),opacity:_expanded?1:0,child: Divider(height: 1,thickness: 1,)),
            AnimatedCrossFade(
              firstChild: Container(height:0),
              secondChild: widget.content,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeOutCubic,
            )
          ],
        ),
      ),
    );
  }
}
