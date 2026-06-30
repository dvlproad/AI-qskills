Pod::Spec.new do |s|
  s.name             = 'AIReplySDK'
  s.version          = '0.1.0'
  s.summary          = 'AI-powered reply generation components for crush messages'
  s.description      = 'A set of reusable SwiftUI components for generating witty, flirty replies to crush messages using AI APIs.'
  s.homepage         = 'https://github.com/dvlproad/AI-qskills'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dvlproad' => 'dvlproad@163.com' }
  s.source           = { :git => 'https://github.com/dvlproad/AI-qskills.git', :tag => s.version.to_s }
  s.ios.deployment_target = '16.0'
  s.swift_version    = '5.9'
  s.frameworks       = 'SwiftUI', 'UIKit', 'Foundation'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/Core/**/*.swift'
    ss.frameworks = 'Foundation'
  end

  s.subspec 'UI' do |ss|
    ss.source_files = 'Sources/UI/**/*.swift'
    ss.frameworks = 'SwiftUI', 'UIKit', 'Foundation'
    ss.dependency 'AIReplySDK/Core'
    ss.dependency 'AIReplySDK/Settings'
  end

  s.subspec 'Settings' do |ss|
    ss.source_files = 'Sources/Settings/**/*.swift'
    ss.frameworks = 'SwiftUI', 'Foundation'
    ss.dependency 'AIReplySDK/Core'
  end
end
