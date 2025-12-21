part of 'card_customizer_bloc.dart';

sealed class CardCustomizerState {
  final int selectedDesignIndex;
  final int selectedColorIndex;
  final String accountName;
  final int accountIndex;
  final List<CardDesign> availableDesigns;
  final List<Gradient> availableColors;

  CardCustomizerState(
    this.selectedDesignIndex,
    this.selectedColorIndex,
    this.availableDesigns,
    this.availableColors,
    this.accountName,
    this.accountIndex,
  );

  CardDesign get selectedDesign {
    return availableDesigns[selectedDesignIndex].withGradient(selectedColor);
  }

  CardCustomizerState copyWith({
    int? selectedDesignIndex,
    int? selectedColorIndex,
    List<CardDesign>? availableDesigns,
    List<Gradient>? availableColors,
    String? accountName,
    int? accountIndex,
  });

  Gradient get selectedColor => availableColors[selectedColorIndex];
}

final class CardCustomizerInitial extends CardCustomizerState {
  CardCustomizerInitial(
    int selectedDesignIndex,
    int selectedColorIndex,
    List<CardDesign> availableDesigns,
    List<Gradient> availableColors,
    String accountName,
    int accountIndex,
  ) : super(selectedDesignIndex, selectedColorIndex, availableDesigns, availableColors, accountName,
            accountIndex);

  CardCustomizerInitial copyWith({
    int? selectedDesignIndex,
    int? selectedColorIndex,
    List<CardDesign>? availableDesigns,
    List<Gradient>? availableColors,
    String? accountName,
    int? accountIndex,
  }) {
    return CardCustomizerInitial(
      selectedDesignIndex ?? this.selectedDesignIndex,
      selectedColorIndex ?? this.selectedColorIndex,
      availableDesigns ?? this.availableDesigns,
      availableColors ?? this.availableColors,
      accountName ?? this.accountName,
      accountIndex ?? this.accountIndex,
    );
  }
}

final class CardCustomizerSaved extends CardCustomizerState {
  CardCustomizerSaved(super.selectedDesignIndex, super.selectedColorIndex, super.availableDesigns,
      super.availableColors, super.accountName, super.accountIndex);

  @override
  CardCustomizerState copyWith(
      {int? selectedDesignIndex,
      int? selectedColorIndex,
      List<CardDesign>? availableDesigns,
      List<Gradient>? availableColors,
      String? accountName,
      int? accountIndex}) {
    return CardCustomizerSaved(
      selectedDesignIndex ?? this.selectedDesignIndex,
      selectedColorIndex ?? this.selectedColorIndex,
      availableDesigns ?? this.availableDesigns,
      availableColors ?? this.availableColors,
      accountName ?? this.accountName,
      accountIndex ?? this.accountIndex,
    );
  }
}
