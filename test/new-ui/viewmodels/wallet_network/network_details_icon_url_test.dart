import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/network_details_bloc.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const bundledIcon = "assets/new-ui/network_icons/optimism.svg";
  const remoteIcon = "https://icons.llamao.fi/icons/chains/rsz_avalanche.jpg";
  const plainHttpIcon = "http://icons.llamao.fi/icons/chains/rsz_avalanche.jpg";

  setUpAll(() => S.current = S());

  group("NetworkDetailsBloc.iconUrlErrorFor", () {
    test("a Popular network's bundled icon passes in ChainList mode", () {
      expect(NetworkDetailsBloc.iconUrlErrorFor(NetworkDetailsMode.chainList, bundledIcon), isNull);
    });

    test("ChainList mode never checks the icon, its field is not shown", () {
      expect(
        NetworkDetailsBloc.iconUrlErrorFor(NetworkDetailsMode.chainList, plainHttpIcon),
        isNull,
      );
    });

    test("the manual modes refuse a URL that is not https", () {
      for (final mode in [NetworkDetailsMode.manualAdd, NetworkDetailsMode.manualEdit]) {
        expect(
          NetworkDetailsBloc.iconUrlErrorFor(mode, plainHttpIcon),
          S.current.url_must_be_https,
          reason: mode.name,
        );
      }
    });

    test("a typed bundled asset path is refused in the manual modes", () {
      expect(
        NetworkDetailsBloc.iconUrlErrorFor(NetworkDetailsMode.manualAdd, "assets/x.png"),
        S.current.url_must_be_https,
      );
      expect(
        NetworkDetailsBloc.iconUrlErrorFor(NetworkDetailsMode.manualEdit, bundledIcon),
        S.current.url_must_be_https,
      );
    });

    test("the manual modes accept an https URL or no icon", () {
      for (final mode in [NetworkDetailsMode.manualAdd, NetworkDetailsMode.manualEdit]) {
        expect(NetworkDetailsBloc.iconUrlErrorFor(mode, remoteIcon), isNull, reason: mode.name);
        expect(NetworkDetailsBloc.iconUrlErrorFor(mode, "  "), isNull, reason: mode.name);
      }
    });
  });
}
