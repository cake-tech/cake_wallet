import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';
import '../../../../core/wallet_connect/models/connection_model.dart';

class ConnectionItemWidget extends StatelessWidget {
  const ConnectionItemWidget({required this.model, Key? key}) : super(key: key);

  final ConnectionModel model;

  @override
  Widget build(BuildContext context) {
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsetsDirectional.only(top: 8),
      child: Visibility(
        visible: model.elements != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.title ?? '',
              style: TextStyle(
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (model.elements != null)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              direction: Axis.horizontal,
              children: model.elements!
                  .map((e) => _ModelElementWidget(model: model, modelElement: e))
                  .toList(),
            ),
          ],
        ),
        replacement: _NoModelElementWidget(model: model),
      ),
    );
  }
}

class _NoModelElementWidget extends StatelessWidget {
  const _NoModelElementWidget({required this.model});

  final ConnectionModel model;

  @override
  Widget build(BuildContext context) {
    return Text(
      model.text!,
      style: TextStyle(
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ModelElementWidget extends StatelessWidget {
  const _ModelElementWidget({
    required this.model,
    required this.modelElement,
  });

  final ConnectionModel model;
  final String modelElement;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: model.elementActions != null ? model.elementActions![modelElement] : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          modelElement,
          style: TextStyle(
            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
