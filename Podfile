platform :ios, '10.0'
# Use Swift dynamic frameworks
use_frameworks!

def ads_pod
	pod 'Google-Mobile-Ads-SDK'
end

target 'Workout Core' do
	ads_pod
	pod 'PersonalizedAdConsent'
end

target 'Workout' do
	ads_pod
end
