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
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '13.0'

  # Built by scripts/prepare_minotari.sh macos
  s.vendored_frameworks = 'Frameworks/minotari_wallet_ffi.framework'
end
