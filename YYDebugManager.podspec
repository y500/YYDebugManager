#
# Be sure to run `pod lib lint YYDebugDatabase.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YYDebugManager'
  s.version          = '1.0.0'
  s.summary          = 'view log and network data on web'

  s.homepage         = 'https://y500.me'
  s.license          = { :type => 'None', :file => 'LICENSE' }
  s.author           = { 'y500' => 'yanqizhou@126.com' }
  s.source           = { :git => 'https://github.com/y500/YYDebugManager.git', :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'

  s.dependency 'GCDWebServer'
  s.dependency 'BLWebSocketsServer'
  s.dependency 'fishhook'

  s.source_files = 'project/*.{h,m}'
  s.public_header_files = 'project/YYDebugManager.h', 'project/YYDebugWKURLSchemeTaskKit.h'
  s.resource = "project/Web.bundle"

  s.requires_arc = true
  s.frameworks = 'Foundation', 'WebKit'

end
