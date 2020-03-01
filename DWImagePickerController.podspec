Pod::Spec.new do |s|
s.name = 'DWImagePickerController'
s.version = '0.0.0.11'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = '一个相册选择库。ImagePicker frameworks.'
s.homepage = 'https://github.com/CodeWicky/DWImagePickerController'
s.authors = { 'codeWicky' => 'codewicky@163.com' }
s.source = { :git => 'https://github.com/CodeWicky/DWImagePickerController.git', :tag => s.version.to_s }
s.requires_arc = true
s.ios.deployment_target = '9.0'
s.source_files = 'DWImagePickerController/**/*.{h,m}'
s.resource = 'DWImagePickerController/DWImagePickerController.bundle'
s.frameworks = 'UIKit'
s.dependency 'DWMediaPreviewController', '~> 0.0.0.43'
s.dependency 'DWAlbumGridController', '~> 0.0.0.9'
s.dependency 'DWKit/DWComponent/DWLabel', '~> 0.0.0.10'
s.dependency 'DWKit/DWUtils/DWAlbumManager', '~> 0.0.0.13'
end
