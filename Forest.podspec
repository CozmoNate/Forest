Pod::Spec.new do |s|
  s.name             = 'Forest'
  s.version          = '1.27.0'
  s.summary          = 'Forest client makes it simple to send requests to web services'
  s.description      = <<-DESC
Forest client is a flexible and extensible RESTful API client framework built on top of `URLSession` and `URLSessionTask`. It includes network object mappers from JSON for the most commonly used data types. Because of its simple data encoding/decoding approach and extensible architecture you can easily add your custom network object mappers. Forest provides most of the features needed to build robust client for your backend services.
DESC
  s.homepage         = 'https://github.com/kzlekk/Forest'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Natan Zalkin' => 'natan.zalkin@me.com' }
  s.source           = { :git => 'https://github.com/kzlekk/Forest.git', :tag => "#{s.version}" }
  s.module_name      = 'Forest'
  s.swift_version    = '5.0'

  s.ios.deployment_target = '10.3'
  s.osx.deployment_target = '10.13'

  s.subspec 'Core' do |cs|
    cs.source_files = 'Forest/Core/*.swift'
    cs.ios.frameworks = 'MobileCoreServices'
  end

  s.subspec 'Protobuf' do |cs|
	cs.dependency 'Forest/Core'
    cs.dependency 'SwiftProtobuf'
	cs.source_files = 'Forest/Protobuf/*.swift'
  end

  s.subspec 'Reachability' do |cs|
    cs.source_files = 'Forest/Reachability/*.swift'
  end

  s.default_subspec = 'Core'

end
