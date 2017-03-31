# Uncomment the next line to define a global platform for your project
platform :ios, '9.3'

use_frameworks!
source 'https://github.com/CocoaPods/Specs.git'

target 'NotificationDemo' do
   pod 'RealmSwift'
   # pod 'RealmSwift', :git => 'https://github.com/realm/realm-cocoa.git', 'submodules: true'
   #pod 'RealmSwift', :git => 'https://github.com/realm/realm-cocoa.git', :branch => 'master' 

   #pod 'Realm', git: 'https://github.com/realm/realm-cocoa.git', branch: 'master', submodules: true
   #pod 'RealmSwift', git: 'https://github.com/realm/realm-cocoa.git', branch: 'master', submodules: true
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
  end