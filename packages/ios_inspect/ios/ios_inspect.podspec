Pod::Spec.new do |s|
  s.name             = 'ios_inspect'
  s.version          = '1.0.0'
  s.summary          = 'Native iOS inspector with liquid glass UI.'
  s.description      = 'Hosts SwiftUI inspector pages and collects system plus signing details.'
  s.homepage         = 'https://github.com/sanjiuyyds/codemagicTest'
  s.license          = { :type => 'MIT' }
  s.author           = { 'sanjiuyyds' => 'sanjiuyyds' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  s.resource_bundles = { 'ios_inspect_privacy' => ['PrivacyInfo.xcprivacy'] }
  s.frameworks = 'UIKit', 'SwiftUI', 'Security', 'Metal'
end
