Pod::Spec.new do |s|
  s.name             = 'Condulet'
  s.version          = '1.5'
  s.summary          = 'Condulet makes it simple to send requests to web services'
  s.description      = <<-DESC
Condulet is a simple wrapper built on top of URLSession and URLSessionTask. Condulet provides most of the features you'll need in your day-by-day work, without stressing you with overcomplicated abstractions.
                       DESC
  s.homepage         = 'https://github.com/kozlek/Condulet'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Natan Zalkin' => 'natan.zalkin@me.com' }
  s.source           = { :git => 'https://github.com/kozlek/Condulet.git', :tag => "#{s.version}" }
  s.module_name      = 'Condulet'
  s.swift_version    = '4.1'

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

  s.default_subspec = 'Core'

end
