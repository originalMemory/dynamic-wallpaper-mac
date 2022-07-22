Pod::Spec.new do |s|
  s.name         = "AutoSQLiteSwift"
  s.version      = '0.0.10'
  s.license      = "MIT"
  s.summary      = '自动解析'

  s.homepage         = 'https://github.com/TonyReet/AutoSQLite.swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 
                          'TonyReet' => 'ktonyreet@gmail.com'
  }

  s.source           = { :git => 'https://github.com/TonyReet/AutoSQLite.swift.git', :tag => s.version.to_s}
  
  s.platform = :osx
  s.osx.deployment_target = "10.10"

  s.source_files = 'Source/*.swift'

  s.dependency 'SQLite.swift', '~> 0.13'
  s.dependency 'HandyJSON', '~> 5.0.2'

end
