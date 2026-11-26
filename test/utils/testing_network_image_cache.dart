import "package:cake_wallet/utils/network_image_cache.dart";
import "package:http/testing.dart";

class TestingNetworkImageCache extends NetworkImageCache {
  TestingNetworkImageCache({required this.client, super.directoryPath});

  final MockClient client;

  @override
  MockClient createClient() => client;
}
