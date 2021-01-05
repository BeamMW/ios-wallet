# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'


post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
            config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        end
    end
end

def shared_pods
    use_frameworks!
    
   # pod 'Crashlytics'
    pod 'SVProgressHUD'
    pod 'SSZipArchive'
   # pod 'Parchment'
    pod 'SwipeTransition'
    pod 'CrashEye'
    pod 'Firebase/Crashlytics'    
    pod 'Firebase/Analytics'
    pod 'PopOverMenu'
end

#def extension
#    use_frameworks!
#    
#    pod 'SSZipArchive'
#    pod 'Firebase/Core'
#    pod 'Firebase/Messaging'
#end

target 'BeamWallet' do
    shared_pods
end

target 'BeamWalletTestNet' do
    shared_pods
end

target 'BeamWalletMasterNet' do
    shared_pods
end



#target 'BeamWalletNotificationViewTestNet' do
#    extension
#end
