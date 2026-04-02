#
# NOTE: This podspec is NOT to be published. It is only used as a local source!
#

Pod::Spec.new do |s|
  s.name             = 'Flutter'
  s.version          = '1.0.0'
  s.summary          = 'High-performance, high-fidelity mobile apps.'
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Flutter' => 'flutter-dev@googlegroups.com' }
  s.source           = { :git => 'https://github.com/flutter/flutter', :tag => s.version.to_s }
  s.ios.deployment_target = '14.0'
  s.vendored_frameworks = 'Flutter.framework'
end