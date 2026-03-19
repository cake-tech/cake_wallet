part of 'card_customizer_bloc.dart';

sealed class CardCustomizerState {
  final int selectedDesignIndex;
  final int selectedColorIndex;
  final String accountName;
  final int accountIndex;
  final int cardOrder;
  final bool displaySats;
  final List<CardDesign> availableDesigns;
  final List<Gradient> availableColors;
  final List<String> availableIconPaths;
  final int selectedIconIndex;

  CardCustomizerState(
    this.selectedDesignIndex,
    this.selectedColorIndex,
    this.availableDesigns,
    this.availableColors,
    this.accountName,
    this.accountIndex,
    this.displaySats,
    this.cardOrder, {
    this.availableIconPaths = const [],
    this.selectedIconIndex = 0,
  });

  CardDesign get selectedDesign {
    var design = availableDesigns[selectedDesignIndex]
        .withGradient(selectedColor);
    if (design.backgroundType == CardDesignBackgroundTypes.svgIcon &&
        availableIconPaths.isNotEmpty) {
      final clamped = selectedIconIndex.clamp(
          0, availableIconPaths.length - 1);
      design = design.withImagePath(availableIconPaths[clamped]);
    }
    return design;
  }

  CardCustomizerState copyWith({
    int? selectedDesignIndex,
    int? selectedColorIndex,
    List<CardDesign>? availableDesigns,
    List<Gradient>? availableColors,
    String? accountName,
    int? accountIndex,
    int? cardOrder,
    List<String>? availableIconPaths,
    int? selectedIconIndex,
  });

  Gradient get selectedColor => availableColors[selectedColorIndex];
}

final class CardCustomizerNotLoaded extends CardCustomizerState {
  CardCustomizerNotLoaded(super.selectedDesignIndex, super.selectedColorIndex, super.availableDesigns, super.availableColors, super.accountName, super.accountIndex, super.displaySats, super.cardOrder);

  @override
  CardCustomizerState copyWith(
      {int? selectedDesignIndex,
      int? selectedColorIndex,
      List<CardDesign>? availableDesigns,
      List<Gradient>? availableColors,
      String? accountName,
      int? accountIndex,
      int? cardOrder,
      List<String>? availableIconPaths,
      int? selectedIconIndex}) {
    // this is never gonna be copied. it's near-instantly replaced with initial
    throw UnimplementedError();
  }
}

final class CardCustomizerInitial extends CardCustomizerState {
  CardCustomizerInitial(
    int selectedDesignIndex,
    int selectedColorIndex,
    List<CardDesign> availableDesigns,
    List<Gradient> availableColors,
    String accountName,
    int accountIndex,
    bool displaySats,
    int cardOrder, {
    List<String> availableIconPaths = const [],
    int selectedIconIndex = 0,
  }) : super(selectedDesignIndex, selectedColorIndex, availableDesigns,
            availableColors, accountName, accountIndex, displaySats, cardOrder,
            availableIconPaths: availableIconPaths,
            selectedIconIndex: selectedIconIndex);

  CardCustomizerInitial copyWith({
    int? selectedDesignIndex,
    int? selectedColorIndex,
    List<CardDesign>? availableDesigns,
    List<Gradient>? availableColors,
    String? accountName,
    int? accountIndex,
    bool? displaySats,
    int? cardOrder,
    List<String>? availableIconPaths,
    int? selectedIconIndex,
  }) {
    return CardCustomizerInitial(
      selectedDesignIndex ?? this.selectedDesignIndex,
      selectedColorIndex ?? this.selectedColorIndex,
      availableDesigns ?? this.availableDesigns,
      availableColors ?? this.availableColors,
      accountName ?? this.accountName,
      accountIndex ?? this.accountIndex,
      displaySats ?? this.displaySats,
      cardOrder ?? this.cardOrder,
      availableIconPaths: availableIconPaths ?? this.availableIconPaths,
      selectedIconIndex: selectedIconIndex ?? this.selectedIconIndex,
    );
  }
}

final class CardCustomizerSaved extends CardCustomizerState {
  CardCustomizerSaved(super.selectedDesignIndex, super.selectedColorIndex,
      super.availableDesigns, super.availableColors, super.accountName,
      super.accountIndex, super.displaySats, super.cardOrder,
      {super.availableIconPaths, super.selectedIconIndex});

  @override
  CardCustomizerState copyWith(
      {int? selectedDesignIndex,
      int? selectedColorIndex,
      List<CardDesign>? availableDesigns,
      List<Gradient>? availableColors,
      String? accountName,
      int? accountIndex,
      bool? displaySats,
      int? cardOrder,
      List<String>? availableIconPaths,
      int? selectedIconIndex}) {
    return CardCustomizerSaved(
      selectedDesignIndex ?? this.selectedDesignIndex,
      selectedColorIndex ?? this.selectedColorIndex,
      availableDesigns ?? this.availableDesigns,
      availableColors ?? this.availableColors,
      accountName ?? this.accountName,
      accountIndex ?? this.accountIndex,
      displaySats ?? this.displaySats,
      cardOrder ?? this.cardOrder,
      availableIconPaths: availableIconPaths ?? this.availableIconPaths,
      selectedIconIndex: selectedIconIndex ?? this.selectedIconIndex,
    );
  }
}
