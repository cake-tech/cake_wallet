#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cw_minotari.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cw_minotari'
  s.version          = '0.0.1'
  s.summary          = 'Cake Wallet Minotari (Tari) integration'
  s.description      = 'Cake Wallet wrapper over Minotari/Tari wallet using Flutter Rust Bridge'
  s.homepage         = 'http://cakewallet.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cake Wallet' => 'support@cakewallet.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'

  # Use xcframework for multi-architecture support (device + simulator)
  s.vendored_frameworks = 'Frameworks/RustMinotari.xcframework'
  s.preserve_paths      = 'Frameworks/RustMinotari.xcframework/**/*'

  # Flutter.framework does not contain a i386 slice
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-lc++ -lz -lsqlite3'
  }
  s.swift_version = '5.0'
end
