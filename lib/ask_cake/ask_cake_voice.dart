import 'package:flutter/services.dart';

/// Voice input for the chat. Speech is turned into text by the system's
/// recogniser running on the device; if this phone or language cannot do that
/// on the device, voice input reports itself unavailable rather than sending
/// audio anywhere. The text lands in the message box for the user to review
/// and send: nothing is sent or acted on by voice alone.
class AskCakeVoice {
  AskCakeVoice({required this.onText, required this.onEnded}) {
    _channel.setMethodCallHandler((call) async {
      final arguments = (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
      switch (call.method) {
        case 'speechText':
          onText(arguments['text'] as String? ?? '');
        case 'speechEnded':
          listening = false;
          // The recogniser can fail before the start call has even returned.
          if (_starting) _failedWhileStarting = arguments['reason'] != null;
          _heardNothing = arguments['reason'] != null;
          onEnded();
      }
    });
  }

  static const _channel = MethodChannel('com.cake_wallet/ask_cake');

  /// The words heard so far in this turn (replaces, not appends).
  final void Function(String text) onText;
  final void Function() onEnded;

  bool listening = false;
  bool _starting = false;
  bool _failedWhileStarting = false;
  bool _heardNothing = false;

  /// True when the last turn of listening ended because recognition could not run.
  bool get lastTurnFailed => _heardNothing;

  /// True while the start call is still in flight (its own result reports any failure).
  bool get starting => _starting;

  /// Null once listening; otherwise a sentence explaining why it could not start.
  Future<String?> start() async {
    try {
      _starting = true;
      _failedWhileStarting = false;
      _heardNothing = false;
      final reply = await _channel.invokeMapMethod<String, dynamic>('speechStart') ?? const {};
      _starting = false;
      if (_failedWhileStarting) {
        listening = false;
        return 'Voice input is not available: this device could not recognise speech on its own.';
      }
      listening = reply['started'] == true;
      if (listening) return null;
      return switch (reply['reason']) {
        'speechDenied' || 'microphoneDenied' =>
          'Voice input needs microphone and speech recognition access. You can allow them in iOS Settings.',
        'onDeviceUnavailable' =>
          'Voice input is not available: this phone cannot recognise speech on the device for your language.',
        _ => 'Voice input is not available right now.',
      };
    } on MissingPluginException {
      _starting = false;
      return 'Voice input is not available on this device.';
    } on PlatformException {
      _starting = false;
      return 'Voice input is not available right now.';
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('speechStop');
    } on MissingPluginException {
      listening = false;
    }
  }

  void dispose() {
    if (listening) stop();
    _channel.setMethodCallHandler(null);
  }
}
