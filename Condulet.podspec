Pod::Spec.new do |s|
  s.name             = 'Condulet'
  s.version          = '1.24.0'
  s.summary          = 'Condulet makes it simple to send requests to web services'
  s.description      = <<-DESC
Condulet is flexible and extensible REST API client construction framework built on top of `URLSession` and `URLSessionTask`. It already inculdes network object mappers from JSON for the most commonly used data types. Because of it simple data encoding/decoding approach and extensible architecture you can easily add your custom network object mappers. Condulet provides most of the features needed to build robust client for your backend services.
DESC
  s.homepage         = 'https://github.com/kozlek/Condulet'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Natan Zalkin' => 'natan.zalkin@me.com' }
  s.source           = { :git => 'https://github.com/kozlek/Condulet.git', :tag => "#{s.version}" }
  s.module_name      = 'Condulet'
  s.swift_version    = '5.0'

  s.ios.deployment_target = '10.0'
  #s.osx.deployment_target = '10.11'
  #s.watchos.deployment_target = '3.0'

  s.subspec 'Core' do |cs|
    cs.source_files = 'Condulet/Core/*.swift'
  end

  s.subspec 'Protobuf' do |cs|
	cs.dependency 'Condulet/Core'
    cs.dependency 'SwiftProtobuf'
	cs.source_files = 'Condulet/Protobuf/*.swift'
  end

  s.subspec 'Reachability' do |cs|
    cs.source_files = 'Condulet/Reachability/*.swift'
  end

  s.default_subspec = 'Core'

end
