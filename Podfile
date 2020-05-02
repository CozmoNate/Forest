source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

project 'Forest'

abstract_target "All Targets" do
    target "Forest" do
        platform :ios, '10.3'
        pod 'SwiftProtobuf'
    end
    target "ForestTests" do
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
