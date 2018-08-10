#
# Be sure to run `pod lib lint OKBluetooth.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OKBluetooth'
  s.version          = '0.1.1'
  s.summary          = 'Bluetooth library using ReactiveCocoa on ios.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                        The easiest way to use Bluetooth (BLE) on ios, using ReactiveCocoa.
                       DESC

  s.homepage         = 'https://github.com/latehorse/OKBluetooth'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yuhanle' => 'deadvia@gmail.com' }
  s.source           = { :git => 'https://github.com/latehorse/OKBluetooth.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/yuhanle'

  s.ios.deployment_target = '8.0'

  s.source_files = 'OKBluetooth/Classes/**/*'
  
  # s.resource_bundles = {
  #   'OKBluetooth' => ['OKBluetooth/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreBluetooth'
  s.dependency 'ReactiveObjC', '3.1.0'
end
