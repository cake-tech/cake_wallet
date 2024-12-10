#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cw_salvium.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cw_salvium'
  s.version          = '0.0.1'
  s.summary          = 'Cake Wallet Salvium'
  s.description      = 'Cake Wallet wrapper over Salvium project'
  s.homepage         = 'http://cakewallet.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cake Wallet' => 'support@cakewallet.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h, Classes/*.h, ../shared_external/ios/libs/monero/include/src/**/*.h, ../shared_external/ios/libs/monero/include/contrib/**/*.h, ../shared_external/ios/libs/monero/include/../shared_external/ios/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'cw_shared_external'
  s.platform = :ios, '10.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
  s.swift_version = '5.0'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/Classes/*.h" }

  s.subspec 'OpenSSL' do |openssl|
    openssl.preserve_paths = '../../../../../cw_shared_external/ios/External/ios/include/**/*.h'
    openssl.vendored_libraries = '../../../../../cw_shared_external/ios/External/ios/lib/libcrypto.a', '../../../../../cw_shared_external/ios/External/ios/lib/libssl.a'
    openssl.libraries = 'ssl', 'crypto'
    openssl.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end

  s.subspec 'Sodium' do |sodium|
    sodium.preserve_paths = '../../../../../cw_shared_external/ios/External/ios/include/**/*.h'
    sodium.vendored_libraries = '../../../../../cw_shared_external/ios/External/ios/lib/libsodium.a'
    sodium.libraries = 'sodium'
    sodium.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end

  s.subspec 'Boost' do |boost|
    boost.preserve_paths = '../../../../../cw_shared_external/ios/External/ios/include/**/*.h',
    boost.vendored_libraries =  '../../../../../cw_shared_external/ios/External/ios/lib/libboost.a',
    boost.libraries = 'boost'
    boost.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end

  s.subspec 'Salvium' do |salvium|
    salvium.preserve_paths = 'External/ios/include/**/*.h'
    salvium.vendored_libraries = 'External/ios/lib/libsalvium.a'
    salvium.libraries = 'salvium'
    salvium.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include" }
  end
end
