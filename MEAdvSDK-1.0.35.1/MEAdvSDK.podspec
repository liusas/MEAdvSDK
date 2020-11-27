Pod::Spec.new do |s|
  s.name = "MEAdvSDK"
  s.version = "1.0.35.1"
  s.summary = "Mobiexchanger's advertise SDK"
  s.license = "{ :type => 'MIT', :file => 'LICENSE' }"
  s.authors = {"刘峰"=>"liufeng@mobiexchanger.com"}
  s.homepage = "https://github.com/liusas/MEAdvSDK.git"
  s.description = "this is a Mobiexchanger's advertise SDK, and we use it as a module"
  s.source = { :path => '.' }

  s.ios.deployment_target    = '9.0'
  s.ios.vendored_framework   = 'ios/MEAdvSDK.framework'
end
