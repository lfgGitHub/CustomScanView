
Pod::Spec.new do |s|

    s.name         = "CustomScanView"
    s.version      = "0.0.1"
    s.summary      = "自定义扫描,适配各种机型，包括ipad"
    s.homepage     = "https://github.com/lfgGitHub/CustomScanView"
    s.license      = "MIT"
    s.author       = { "weiyang" => "meng852163550@163.com" }
    s.platform     = :ios, "6.0"
    s.source       = { :git => "https://github.com/lfgGitHub/CustomScanView.git", :tag => "0.0.1" }
    s.source_files  = "CustomScanView", "*.{h,m}"
    s.requires_arc = true
    s.dependency "Masonry", "~> 0.6.0"

end