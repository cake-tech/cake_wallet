import 'package:flutter/material.dart';

class PickerItemWidget extends StatelessWidget {
  const PickerItemWidget(
      {required this.title, this.iconPath, this.isSelected = false, this.tag, this.onTap});

  final String? iconPath;
  final String title;
  final bool isSelected;
  final String? tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
          child: Row(
            children: [
              Container(
                child: Image.asset(
                  iconPath ?? '',
                  height: 20.0,
                  width: 20.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: isSelected ? 16 : 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (tag != null)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 35.0,
                          height: 18.0,
                          child: Center(
                            child: Text(
                              tag!,
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 7.0, color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.0),
                            //border: Border.all(color: ),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
