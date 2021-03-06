Pod::Spec.new do |s|
  s.name = "Gifu"
  s.version = "2.0.0"
  s.summary = "High-performance animated GIF support for iOS "
  s.homepage = "https://github.com/kaishin/Gifu"
  s.social_media_url = "http://twitter.com/kaishin"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Reda Lemeden" => "git@kaishin.haz.email" }
  s.source = { :git => "https://github.com/Ginger-Labs/Gifu.git", :tag => "v#{s.version}", :submodules => true }
  s.platform = :ios, "8.0"
  s.ios.source_files = "Source/**/*.{h,swift}"
  s.requires_arc = true
end
