# 来自下方 git 页面，因为原插件使用 Swift Package Manager ，故修改增加 podsepc 方式

Pod::Spec.new do |s|
  s.name             = 'GIFImage'
  s.version          = '0.0.0'
  s.summary          = '播放 gif 的 View'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  This package contains a SwiftUI View that is able to render a GIF, either from a remote URL, or from a local Data. The component was born from the wish to try out the Combine Framework, and it is more of a learning tool than a production ready code.
                       DESC

  s.homepage         = 'https://github.com/igorcferreira/GIFImage'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'igorcferreira' => '' }
  s.source           = { :git => 'https://github.com/igorcferreira/GIFImage.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform = :osx
  s.osx.deployment_target = "10.10"

  s.source_files = 'GIFImage/Classes/**/*'

  # s.resource_bundles = {
  #   'GIFImage' => ['GIFImage/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'Cocoa'
  # s.dependency 'AFNetworking', '~> 2.3'
end
