
Pod::Spec.new do |s|

  s.name         = "WKScrollMenu"
  s.version      = "0.0.1"
  s.summary      = "A simple scrollMenu"
  s.homepage     = "https://github.com/weaken000/WKScrollMenu"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "weikun" => "845188093@qq.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/weaken000/WKScrollMenu.git", :tag => s.version }
  s.source_files = "WKScrollMenu"
  s.requires_arc = true

end
