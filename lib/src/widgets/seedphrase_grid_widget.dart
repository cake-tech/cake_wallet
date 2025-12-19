import 'package:flutter/material.dart';

class SeedPhraseGridWidget extends StatelessWidget {
  const SeedPhraseGridWidget({
    super.key,
    required this.list,
  });

  final List<String> list;



  @override
  Widget build(BuildContext context) {
    int minTiles = 1;
    int maxTiles = 4;
    double desiredTileWidth = 120;
    double spacing = 4;
    double padding = 4;
    double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount =
        ((screenWidth + spacing - (2 * padding)) / (desiredTileWidth + spacing)).floor();


    if (crossAxisCount > maxTiles) crossAxisCount = maxTiles;
    if (crossAxisCount < minTiles) crossAxisCount = minTiles;

    return GridView.builder(
      itemCount: list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.6,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final numberCount = index + 1;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                child: Text(
                  numberCount.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.9,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                  softWrap: true,
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item[0].toLowerCase()}${item.substring(1)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
