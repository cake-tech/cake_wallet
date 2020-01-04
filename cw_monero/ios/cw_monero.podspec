#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cw_monero.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cw_monero'
  s.version          = '0.0.2'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h, Classes/*.h, External/ios/libs/monero/include/src/**/*.h, External/ios/libs/monero/include/contrib/**/*.h, External/ios/libs/monero/include/External/ios/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.swift_version = '4.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS' => 'arm64' }
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/Classes/*.h" }

  s.subspec 'OpenSSL' do |openssl|
    openssl.preserve_paths = 'External/ios/libs/OpenSSL/include/openssl/*.h', 'External/ios/libs/OpenSSL/include/LICENSE'
    openssl.vendored_libraries = 'External/ios/libs/OpenSSL/lib/libcrypto.a', 'External/ios/libs/OpenSSL/lib/libssl.a'
    openssl.libraries = 'ssl', 'crypto'
    openssl.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/libs/OpenSSL/include/**" }
  end

  s.subspec 'Monero' do |monero|
    monero.preserve_paths = 'External/ios/libs/monero/include/src/**/*.h', 'External/ios/libs/monero/include/External/ios/**/*.h', 'External/ios/libs/monero/include/contrib/**/*.h'
    monero.vendored_libraries = 'External/ios/libs/monero/libs/lib-ios/*.a'
    monero.libraries = 'easylogging', 'epee', 'unbound', 'wallet_merged', 'lmdb', 'randomx'
    monero.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/libs/monero/include/src/**" }
  end

  s.subspec 'Boost' do |boost|
    boost.preserve_paths = 'External/ios/libs/boost/include/**/*.h', 'External/ios/libs/boost/include/**/*.h'
    boost.vendored_libraries = 'External/ios/libs/boost/build/libs/universal/*.a'
    boost.libraries = 'boost', 'boost_wserialization', 'boost_thread', 'boost_system', 'boost_signals', 'boost_serialization', 'boost_regex', 'boost_random', 'boost_program_options', 'boost_locale', 'boost_graph', 'boost_filesystem', 'boost_date_time', 'boost_chrono'
    boost.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/libs/boost/include/**" }
  end

  s.subspec 'Sodium' do |sodium|
    sodium.preserve_paths = 'External/ios/libs/sodium/include/**/*.h'
    sodium.vendored_libraries = 'External/ios/libs/sodium/lib/libsodium.a'
    sodium.libraries = 'sodium'
    sodium.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/libs/sodium/include/**" }
  end
end