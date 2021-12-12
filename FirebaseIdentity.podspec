Pod::Spec.new do |s|
  s.name             = 'FirebaseIdentity'
  s.version          = '1.4.0'
  s.summary          = 'A lightweight library that streamlines interaction with the Firebase/Auth library on iOS, written in Swift.'
  s.description      = <<-DESC
  The primary motivation of this library is to make building custom UI around the Firebase Authentication
  service easier on iOS for those of us that do not want to use the FirebaseUI library. It does this by
  implementing standard authentication workflows and error handling (i.e. account linking, profile updates,
  set/update password, reauthentication, enable/disable thrid-party identity providers, account deletion,
  auto-retry, etc.). This is done by abstracting away a lot of the error handling logic into a singleton
  state machine (called AuthManager) capable of handling most Firebase authentication use cases.
                       DESC
  s.homepage         = 'https://github.com/cgossain/FirebaseIdentity'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cgossain' => 'cgossain@gmail.com' }
  s.source           = { :git => 'https://github.com/cgossain/FirebaseIdentity.git', :tag => s.version.to_s }
  s.swift_version    = '5.0'
  s.static_framework = true
  s.ios.deployment_target = '12.4'

  s.source_files = 'FirebaseIdentity/Classes/**/*'
  # s.resource_bundles = {
  #     'FirebaseIdentity-Assets' => ['MooveFitCoreKit/Assets/**/*']
  # }
  
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Database'
  s.dependency 'ProcedureKit'
end

