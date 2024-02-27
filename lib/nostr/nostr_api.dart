import 'dart:convert';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/nostr/nostr_user.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:nostr_tools/nostr_tools.dart';

class NostrProfileHandler {
  static final relayToDomainMap = {
    'relay.snort.social': 'snort.social',
  };

  static Nip05 _nip05 = Nip05();

  static Future<ProfilePointer?> queryProfile(BuildContext context, String nip05Address) async {
    var profile = await _nip05.queryProfile(nip05Address);
    if (profile?.pubkey != null) {
      if (profile?.relays?.isNotEmpty == true) {
        return profile;
      } else {
        await _showErrorDialog(context, S.of(context).no_relays, S.of(context).no_relays_message);
      }
    }
    return null;
  }

  static Future<UserMetadata?> processRelays(
      BuildContext context, ProfilePointer profile, String nip05Address) async {
    String userDomain = _extractDomain(nip05Address);
    const int metaData = 0;

    for (String relayUrl in profile.relays ?? []) {
      final relayDomain = _getDomainFromRelayUrl(relayUrl);
      final formattedRelayDomain = relayToDomainMap[relayDomain] ?? relayDomain;
      if (formattedRelayDomain == userDomain) {
        final userDomainData = await _fetchInfoFromRelay(relayUrl, profile.pubkey, [metaData]);
        if (userDomainData != null) {
          return userDomainData;
        }
      }
    }
    await _showErrorDialog(context, S.of(context).no_relays, S.of(context).no_relay_on_domain);

    String? chosenRelayUrl = await _showRelayChoiceDialog(context, profile.relays ?? []);
    if (chosenRelayUrl != null) {
      final userData = await _fetchInfoFromRelay(chosenRelayUrl, profile.pubkey, [metaData]);
      if (userData != null) {
        return userData;
      }
    }

    return null;
  }

  static Future<UserMetadata?> _fetchInfoFromRelay(
      String relayUrl, String userPubKey, List<int> kinds) async {
    try {
      final relay = RelayApi(relayUrl: relayUrl);
      final stream = await relay.connect();

      relay.sub([
        Filter(
          kinds: kinds,
          authors: [userPubKey],
        )
      ]);

      await for (var message in stream) {
        if (message.type == 'EVENT') {
          final event = message.message as Event;

          final eventContent = json.decode(event.content) as Map<String, dynamic>;

          final userMetadata = UserMetadata.fromJson(eventContent);
          relay.close();
          return userMetadata;
        }
      }

      relay.close();
      return null;
    } catch (e) {
      print('[!] Error with relay $relayUrl: $e');
      return null;
    }
  }

  static Future<void> _showErrorDialog(
      BuildContext context, String title, String errorMessage) async {
    if (context.mounted) {
      await showPopUp<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertWithOneAction(
            alertTitle: title,
            alertContent: errorMessage,
            buttonText: S.of(dialogContext).ok,
            buttonAction: () => Navigator.of(dialogContext).pop(),
          );
        },
      );
    }
  }

  static String _extractDomain(String nip05Address) {
    var parts = nip05Address.split('@');
    return parts.length == 2 ? parts[1] : '';
  }

  static String _getDomainFromRelayUrl(String relayUrl) {
    try {
      var uri = Uri.parse(relayUrl);
      return uri.host;
    } catch (e) {
      print('Error parsing URL: $e');
      return '';
    }
  }

  static Future<String?> _showRelayChoiceDialog(BuildContext context, List<String> relays) async {
    String? selectedRelay;

    if (context.mounted) {
      await showPopUp<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return Picker<String>(
            selectedAtIndex: 0,
            title: S.of(dialogContext).choose_relay,
            items: relays,
            onItemSelected: (String relay) => selectedRelay = relay,
          );
        },
      );
    }

    return selectedRelay;
  }
}
