Pod::Spec.new do |s|

s.name         = "CustomScanView"
s.version      = "1.1.0"
s.summary      = "自定义扫描,适配各种机型，包括ipad，同时适配iOS11和iPhone X"
s.homepage     = "https://github.com/lfgGitHub/CustomScanView"
s.license      = { :type => "MIT", :file => "LICENSE" }
s.author       = { "Mr.Li" => "meng852163550@163.com" }
s.platform     = :ios, "6.0"
s.source       = { :git => "https://github.com/lfgGitHub/CustomScanView.git", :tag => "1.1.0" }
s.source_files  = "CustomScanView", "CustomScanProject/CustomScanView/*.{h,m}"
s.requires_arc = true
s.dependency "Masonry", "~> 0.6.0"

end
