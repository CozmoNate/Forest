source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

project 'Condulet'

abstract_target "All Targets" do
    target "Condulet" do
        platform :ios, '10.3'
        pod 'SwiftProtobuf'
    end
    target "ConduletTests" do
        platform :ios, '10.3'
        pod 'Quick'
        pod 'Nimble'
        pod 'Mockingjay', :git => 'https://github.com/kylef/Mockingjay.git'
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.3'
      end
    end
end
