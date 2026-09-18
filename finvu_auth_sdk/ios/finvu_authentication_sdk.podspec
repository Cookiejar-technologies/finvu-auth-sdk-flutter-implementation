#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint finvu_authentication_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'finvu_authentication_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Finvu Auth SDK Flutter plugin — Silent Network Authentication for Account Aggregator flows.'
  s.description      = <<-DESC
Flutter plugin wrapping the Finvu Authentication SDK. Provides Silent Network
Authentication (SNA) and WebView bridge support for iOS and Android.
                       DESC
  s.homepage         = 'https://github.com/Cookiejar-technologies/finvu-auth-sdk-flutter-implementation'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cookiejar Technologies' => 'support@cookiejar.co.in' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Download FinvuAuthenticationSDK from public GitHub repo
  # Pinned to v1.0.5 deliberately — this no longer tracks the React Native
  # wrapper's version. On version bump: update v1.0.5 and 1.0.5 below to match
  # the new tag.
  s.prepare_command = <<-CMD
    curl -sSL https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios/archive/refs/tags/v1.0.5.tar.gz | tar -xz --strip-components=1 finvu-auth-sdk-ios-1.0.5/FinvuAuthenticationSDK.xcframework
  CMD

  s.vendored_frameworks = 'FinvuAuthenticationSDK.xcframework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'finvu_auth_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
