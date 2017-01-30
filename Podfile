platform :ios, '9.0'

target 'Workout' do
	# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
	use_frameworks!

	# Pods for Workout
	pod 'Google-Mobile-Ads-SDK'

end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings['SWIFT_VERSION'] = '3.0'
		end
	end
end
