#
# Be sure to run `pod lib lint MobiAdSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MobiAdSDK'
  s.version          = '1.0.4'
  s.summary          = 'A short description of MobiAdSDK.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Liusas/MobiAdSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Liusas' => 'liufeng@mobiexchanger.com' }
  s.source           = { :git => 'https://github.com/Liusas/MobiAdSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'MEAdvSDK/Classes/**/*'
  s.resource = "MEAdvSDK/Assets/Resource/*"
  
  # s.resource_bundles = {
  #   'MobiAdSDK' => ['MobiAdSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Bytedance-UnionAD', '3.2.6.2'
  s.dependency "GDTMobSDK", "~> 4.11.11"
  s.dependency 'KSAdSDK', '~> 3.3.3'
end
