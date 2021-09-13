#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cw_monero.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cw_monero'
  s.version          = '0.0.2'
  s.summary          = 'CW Monero'
  s.description      = 'Cake Wallet wrapper over Monero project.'
  s.homepage         = 'http://cakewallet.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CakeWallet' => 'support@cakewallet.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h, Classes/*.h, External/ios/libs/monero/include/src/**/*.h, External/ios/libs/monero/include/contrib/**/*.h, External/ios/libs/monero/include/External/ios/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'
  s.swift_version = '4.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/Classes/*.h" }

  s.subspec 'OpenSSL' do |openssl|
    openssl.preserve_paths = 'External/ios/include/*.h'
    openssl.vendored_libraries = 'External/ios/lib/libcrypto.a', 'External/ios/lib/libssl.a'
    openssl.libraries = 'ssl', 'crypto'
    openssl.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end

  s.subspec 'Monero' do |monero|
    monero.preserve_paths = 'External/ios/include/**/*.h'
    monero.vendored_libraries = 'External/ios/lib/libeasylogging.a', 'External/ios/lib/libepee.a', 'External/ios/lib/liblmdb.a', 'External/ios/lib/librandomx.a', 'External/ios/lib/libunbound.a', 'External/ios/lib/libwallet_merged.a', 'libcryptonote_basic.a', 'libcryptonote_format_utils_basic.a'
    monero.libraries = 'easylogging', 'epee', 'unbound', 'wallet_merged', 'lmdb', 'randomx', 'cryptonote_basic', 'cryptonote_format_utils_basic'
    monero.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include" }
  end

  s.subspec 'Boost' do |boost|
    boost.preserve_paths = 'External/ios/include/**/*.h', 'External/ios/include/**/*.h'
    boost.vendored_libraries = 'External/ios/lib/libboost_chrono.a', 'External/ios/lib/libboost_date_time.a', 'External/ios/lib/libboost_filesystem.a', 'External/ios/lib/libboost_graph.a', 'External/ios/lib/libboost_locale.a', 'External/ios/lib/libboost_program_options.a', 'External/ios/lib/libboost_random.a', 'External/ios/lib/libboost_regex.a', 'External/ios/lib/libboost_serialization.a', 'External/ios/lib/libboost_system.a', 'External/ios/lib/libboost_thread.a', 'External/ios/lib/libboost_wserialization.a'
    boost.libraries = 'boost_wserialization', 'boost_thread', 'boost_system', 'boost_serialization', 'boost_regex', 'boost_random', 'boost_program_options', 'boost_locale', 'boost_graph', 'boost_filesystem', 'boost_date_time', 'boost_chrono'
    boost.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end

  s.subspec 'Sodium' do |sodium|
    sodium.preserve_paths = 'External/ios/include/**/*.h'
    sodium.vendored_libraries = 'External/ios/lib/libsodium.a'
    sodium.libraries = 'sodium'
    sodium.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end

  s.subspec 'lmdb' do |lmdb|
    lmdb.vendored_libraries = 'External/ios/lib/liblmdb.a'
    lmdb.libraries = 'lmdb'
  end
end
