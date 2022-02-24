#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cw_shared_external.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cw_shared_external'
  s.version          = '0.0.1'
  s.summary          = 'Shared libraries for monero and haven.'
  s.description      = 'Shared libraries for monero and haven.'
  s.homepage         = 'http://cakewallet.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cake Wallet' => 'm@cakewallet.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
  s.swift_version = '5.0'

  s.subspec 'OpenSSL' do |openssl|
    openssl.preserve_paths = 'External/ios/include/*.h'
    openssl.vendored_libraries = 'External/ios/lib/libcrypto.a', 'External/ios/lib/libssl.a'
    openssl.libraries = 'ssl', 'crypto'
    openssl.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end

  s.subspec 'Boost' do |boost|
    boost.preserve_paths = 'External/ios/include/**/*.h'
    boost.vendored_libraries = 'External/ios/lib/libboost.a',
    boost.libraries = 'boost'
    boost.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end

  s.subspec 'Sodium' do |sodium|
    sodium.preserve_paths = 'External/ios/include/**/*.h'
    sodium.vendored_libraries = 'External/ios/lib/libsodium.a'
    sodium.libraries = 'sodium'
    sodium.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/External/ios/include/**" }
  end
end
