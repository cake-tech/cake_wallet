#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cw_pivx.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cw_pivx'
  s.version          = '0.0.1'
  s.summary          = 'PIVX integration for Cake Wallet with Sapling support.'
  s.description      = <<-DESC
PIVX cryptocurrency integration for Cake Wallet, including
full Sapling shielded transaction support via native Rust library.
                       DESC
  s.homepage         = 'https://cakewallet.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cake Wallet' => 'support@cakewallet.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => '-lresolv'
  }
  s.swift_version = '5.0'

  # Link the Sapling native library
  s.vendored_libraries = 'Frameworks/libcw_pivx_sapling.a'
  s.preserve_paths = 'Frameworks/**/*'

end
