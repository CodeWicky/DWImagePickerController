Pod::Spec.new do |s|
s.name = 'DWImagePickerController'
s.version = '0.0.0.1'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = '一个相册选择库。ImagePicker frameworks.'
s.homepage = 'https://github.com/CodeWicky/DWImagePickerController'
s.authors = { 'codeWicky' => 'codewicky@163.com' }
s.source = { :git => 'https://github.com/CodeWicky/DWImagePickerController.git', :tag => s.version.to_s }
s.requires_arc = true
s.ios.deployment_target = '9.1'
s.source_files = 'DWImagePickerController/**/*.{h,m}'
s.frameworks = 'UIKit'
s.dependency 'DWMediaPreviewController', '~> 0.0.0.6'

end
