part of 'card_customizer_bloc.dart';

sealed class CardCustomizerState {
  final int selectedDesignIndex;
  final int selectedColorIndex;
  final String accountName;
  final int accountIndex;
  final List<CardDesign> availableDesigns;

  CardCustomizerState(
    this.selectedDesignIndex,
    this.selectedColorIndex,
    this.availableDesigns,
    this.accountName,
    this.accountIndex,
  );

  CardDesign get selectedDesign {
    if (availableDesigns[selectedDesignIndex].backgroundType == CardDesignBackgroundTypes.svgIcon) {
      return availableDesigns[selectedDesignIndex].withGradient(selectedColor);
    } else {
      return availableDesigns[selectedDesignIndex];
    }
  }

  CardCustomizerState copyWith({
    int? selectedDesignIndex,
    int? selectedColorIndex,
    List<CardDesign>? availableDesigns,
    String? accountName,
    int? accountIndex,
  });

  Gradient get selectedColor => CardDesign.allGradients[selectedColorIndex];
}

final class CardCustomizerInitial extends CardCustomizerState {
  CardCustomizerInitial(
    int selectedDesignIndex,
    int selectedColorIndex,
    List<CardDesign> availableDesigns,
    String accountName,
    int accountIndex,
  ) : super(selectedDesignIndex, selectedColorIndex, availableDesigns, accountName, accountIndex);

  CardCustomizerInitial copyWith({
    int? selectedDesignIndex,
    int? selectedColorIndex,
    List<CardDesign>? availableDesigns,
    String? accountName,
    int? accountIndex,
  }) {
    return CardCustomizerInitial(
      selectedDesignIndex ?? this.selectedDesignIndex,
      selectedColorIndex ?? this.selectedColorIndex,
      availableDesigns ?? this.availableDesigns,
      accountName ?? this.accountName,
      accountIndex ?? this.accountIndex,
    );
  }
}

final class CardCustomizerSaved extends CardCustomizerState {
  CardCustomizerSaved(super.selectedDesignIndex, super.selectedColorIndex, super.availableDesigns,
      super.accountName, super.accountIndex);

  @override
  CardCustomizerState copyWith(
      {int? selectedDesignIndex,
      int? selectedColorIndex,
      List<CardDesign>? availableDesigns,
      String? accountName,
      int? accountIndex}) {
    return CardCustomizerSaved(
      selectedDesignIndex ?? this.selectedDesignIndex,
      selectedColorIndex ?? this.selectedColorIndex,
      availableDesigns ?? this.availableDesigns,
      accountName ?? this.accountName,
      accountIndex ?? this.accountIndex,
    );
  }
}
