#
# Run `pod lib lint netpulse.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'netpulse'
  s.version          = '0.1.0'
  s.summary          = 'Offline-first connectivity intelligence for Flutter.'
  s.description      = <<-DESC
Live network status, internet verification, diagnostics, quality scoring and
local connection history for Flutter applications.
                       DESC
  s.homepage         = 'https://github.com/iamrama/netpulse-connectivity-sdk'
  s.license          = { :type => 'Apache-2.0', :file => '../LICENSE' }
  s.author           = 'NetPulse contributors'
  s.source           = { :path => '.' }
  s.source_files = 'netpulse/Sources/netpulse/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'Network'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'netpulse_privacy' => ['netpulse/Sources/netpulse/PrivacyInfo.xcprivacy']}
end
