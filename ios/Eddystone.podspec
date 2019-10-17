
Pod::Spec.new do |s|
  s.name         = "Eddystone"
  s.version      = "1.0.0"
  s.summary      = "Eddystone"
  s.description  = <<-DESC
                  Eddystone
                   DESC
  s.homepage     = "https://github.com/lg2/react-native-eddystone"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/lg2/react-native-eddystone", :tag => "master" }
  s.source_files  = "**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end


