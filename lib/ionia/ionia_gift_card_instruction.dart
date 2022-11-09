import 'dart:convert';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

class IoniaGiftCardInstruction {
    IoniaGiftCardInstruction(this.header, this.body);

    factory IoniaGiftCardInstruction.fromJsonMap(Map<String, dynamic> element) {
        return IoniaGiftCardInstruction(
            toBeginningOfSentenceCase(element['title'] as String? ?? '') ?? '',
            element['description'] as String);
    }

    static List<IoniaGiftCardInstruction> parseListOfInstructions(String instructionsJSON) {
        List<IoniaGiftCardInstruction> instructions = <IoniaGiftCardInstruction>[];

        if (instructionsJSON.isNotEmpty) {
            final decodedInstructions = json.decode(instructionsJSON) as List<dynamic>;
            instructions = decodedInstructions
                    .map((dynamic e) =>IoniaGiftCardInstruction.fromJsonMap(e as Map<String, dynamic>))
                    .toList();
        }

        return instructions;
    }

    final String header;
    final String body;
}