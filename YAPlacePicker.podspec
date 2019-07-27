#
# Be sure to run `pod lib lint YAPlacePicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YAPlacePicker'
  s.version          = '0.3.7'
  s.summary          = 'Yet Another Place Picker for Google Maps'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'YAPlacePicker is a replacement for deprecated GooglePlacePicker'

  s.homepage         = 'https://github.com/nkhoudor/YAPlacePicker'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nikita Khudorozhkov' => '7633277@gmail.com' }
  s.source           = { :git => 'https://github.com/nkhoudor/YAPlacePicker.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'YAPlacePicker/Classes/**/*'
  
  s.resources = 'YAPlacePicker/Assets/**/*'
  
  # s.resource_bundles = {
  #   'YAPlacePicker' => ['YAPlacePicker/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  s.dependency 'GoogleMaps'
  s.dependency 'GooglePlaces'
  s.dependency 'RxSwift', '4.5'
  s.dependency 'RxCocoa', '4.5'
  
  s.static_framework = true
  
  s.swift_version = '4.2'
end
