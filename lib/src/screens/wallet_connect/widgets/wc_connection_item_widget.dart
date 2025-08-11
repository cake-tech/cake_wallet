import 'package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart';
import 'package:flutter/material.dart';

class WCConnectionItemWidget extends StatelessWidget {
  const WCConnectionItemWidget({required this.model, Key? key}) : super(key: key);

  final WCConnectionModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
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
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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

  final WCConnectionModel model;

  @override
  Widget build(BuildContext context) {
    return Text(
      model.text!,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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

  final WCConnectionModel model;
  final String modelElement;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: model.elementActions != null ? model.elementActions![modelElement] : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          modelElement,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 50,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
