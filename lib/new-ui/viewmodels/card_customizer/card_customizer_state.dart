part of 'card_customizer_bloc.dart';

sealed class CardCustomizerState {
  final int selectedDesignIndex;
  final int selectedColorIndex;
  final String accountName;
  final int accountIndex;
  final int cardOrder;
  final List<CardDesign> availableDesigns;
  final List<Gradient> availableColors;

  CardCustomizerState(
    this.selectedDesignIndex,
    this.selectedColorIndex,
    this.availableDesigns,
    this.availableColors,
    this.accountName,
    this.accountIndex,
      this.cardOrder
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
    int? cardOrder,
  });

  Gradient get selectedColor => availableColors[selectedColorIndex];
}

final class CardCustomizerNotLoaded extends CardCustomizerState {
  CardCustomizerNotLoaded(super.selectedDesignIndex, super.selectedColorIndex, super.availableDesigns, super.availableColors, super.accountName, super.accountIndex, super.cardOrder);

  @override
  CardCustomizerState copyWith({int? selectedDesignIndex, int? selectedColorIndex, List<CardDesign>? availableDesigns, List<Gradient>? availableColors, String? accountName, int? accountIndex, int? cardOrder}) {
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
      int cardOrder,
  ) : super(selectedDesignIndex, selectedColorIndex, availableDesigns, availableColors, accountName,
            accountIndex, cardOrder);

  CardCustomizerInitial copyWith({
    int? selectedDesignIndex,
    int? selectedColorIndex,
    List<CardDesign>? availableDesigns,
    List<Gradient>? availableColors,
    String? accountName,
    int? accountIndex,
    int? cardOrder,
  }) {
    return CardCustomizerInitial(
      selectedDesignIndex ?? this.selectedDesignIndex,
      selectedColorIndex ?? this.selectedColorIndex,
      availableDesigns ?? this.availableDesigns,
      availableColors ?? this.availableColors,
      accountName ?? this.accountName,
      accountIndex ?? this.accountIndex,
      cardOrder ?? this.cardOrder,
    );
  }
}

final class CardCustomizerSaved extends CardCustomizerState {
  CardCustomizerSaved(super.selectedDesignIndex, super.selectedColorIndex, super.availableDesigns,
      super.availableColors, super.accountName, super.accountIndex, super.cardOrder);

  @override
  CardCustomizerState copyWith(
      {int? selectedDesignIndex,
      int? selectedColorIndex,
      List<CardDesign>? availableDesigns,
      List<Gradient>? availableColors,
      String? accountName,
      int? accountIndex,
      int? cardOrder}) {
    return CardCustomizerSaved(
      selectedDesignIndex ?? this.selectedDesignIndex,
      selectedColorIndex ?? this.selectedColorIndex,
      availableDesigns ?? this.availableDesigns,
      availableColors ?? this.availableColors,
      accountName ?? this.accountName,
      accountIndex ?? this.accountIndex,
      cardOrder ?? this.cardOrder,
    );
  }
}
