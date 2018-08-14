Pod::Spec.new do |s|
  s.name             = 'OKBluetooth'
  s.version          = '0.1.2'
  s.summary          = 'Bluetooth library using ReactiveCocoa on ios.'

  s.description      = <<-DESC
                    The easiest way to use Bluetooth (BLE) on ios, using ReactiveCocoa.
                       DESC

  s.homepage         = 'https://github.com/latehorse/OKBluetooth'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yuhanle' => 'deadvia@gmail.com' }
  s.source           = { :git => 'https://github.com/latehorse/OKBluetooth.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/yuhanle'

  s.ios.deployment_target = '7.0'
  
  s.source_files = 'OKBluetooth/Classes/**/*'
  s.frameworks = 'CoreBluetooth'
  s.dependency 'ReactiveObjC', '3.1.0'
end
