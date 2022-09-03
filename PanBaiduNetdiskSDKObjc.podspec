Pod::Spec.new do |s|
  s.name         = 'PanBaiduNetdiskSDKObjc'
  s.version      = '0.0.1'
  s.summary      = 'A pleasant wrapper around the Pan Baidu Netdisk API.'
  s.homepage     = 'https://github.com/leshkoapps/PanBaiduNetdiskSDKObjc.git'
  s.author       = { 'Everappz' => 'https://everapz.com' }
  s.source       = { :git => 'https://github.com/leshkoapps/PanBaiduNetdiskSDKObjc.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.platform     = :ios, '9.0'
  s.source_files = 'SDK/*.{h,m}'
  s.license = 'MIT'
  s.framework    = 'Foundation', 'WebKit'
  s.dependency 'ISO8601DateFormatter'
end