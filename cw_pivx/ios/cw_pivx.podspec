#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cw_pivx.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cw_pivx'
  s.version          = '0.0.1'
  s.summary          = 'PIVX integration for Cake Wallet with Sapling support.'
  s.description      = <<-DESC
PIVX wallet for Cake Wallet with Sapling shielded transactions,
backed by a native Rust library for proving and note scanning.
                       DESC
  s.homepage         = 'https://cakewallet.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cake Wallet' => 'support@cakewallet.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.libraries = 'resolv'

  # Preserve the xcframework
  s.preserve_paths = 'Frameworks/**/*'

  # Script to copy the correct .a file based on SDK
  copy_script = 'if [[ "$PLATFORM_NAME" == *"simulator"* ]]; then cp "${PODS_TARGET_SRCROOT}/Frameworks/cw_pivx_sapling.xcframework/ios-arm64_x86_64-simulator/libcw_pivx_sapling.a" "${BUILT_PRODUCTS_DIR}/libcw_pivx_sapling.a"; else cp "${PODS_TARGET_SRCROOT}/Frameworks/cw_pivx_sapling.xcframework/ios-arm64/libcw_pivx_sapling.a" "${BUILT_PRODUCTS_DIR}/libcw_pivx_sapling.a"; fi'

  s.script_phase = {
    :name => 'Copy PIVX Sapling Library',
    :script => copy_script,
    :execution_position => :before_compile,
    :output_files => ['${BUILT_PRODUCTS_DIR}/libcw_pivx_sapling.a']
  }

  # Flutter.framework does not contain a i386 slice.
  # Use -force_load to embed static library symbols into the cw_pivx dynamic framework
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libcw_pivx_sapling.a'
  }
  s.swift_version = '5.0'

end
