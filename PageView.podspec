Pod::Spec.new do |s|
  s.name                      = "PageView"
  s.version                   = "1.0.0"
  s.summary                   = "An infinite scrolling control inspired by UIPageViewController"
  s.homepage                  = "https://github.com/ronnyf/PageView"
  s.license                   = "MIT"
  s.author                    = { "Ronny Falk" => "ronny@rfxsoftware.com" }
  s.ios.deployment_target     = "8.0"
  #s.osx.deployment_target     = "10.10"
  #s.tvos.deployment_target    = "9.0"
  #s.watchos.deployment_target = "2.0"
  s.source                    = { :git => "https://github.com/ronnyf/PageView.git",
                                  :tag => s.version.to_s }
  s.requires_arc              = true
  s.source_files              = "source/**/*.swift"
  s.module_name               = "PageView"
end