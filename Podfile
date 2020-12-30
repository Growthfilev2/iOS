# Uncomment the next line to define a global platform for your project
platform :ios, '14'
use_frameworks!

target 'GrowthfileNewApp' do
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
  pod 'Firebase/DynamicLinks'
  pod 'FacebookSDK'
  pod 'FacebookCore'

end
  
post_install do |pi|
    pi.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14'
      end
    end
end
