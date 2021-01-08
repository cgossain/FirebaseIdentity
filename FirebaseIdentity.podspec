Pod::Spec.new do |s|
  s.name             = 'FirebaseIdentity'
  s.version          = '1.1.0'
  s.summary          = 'A lightweight library that simplifies dealing with Firebase Authentication iOS SDK, written in Swift.'
  s.description      = <<-DESC
  Firebase Authentication is a powerful service that can be implemented in many different ways. This library aims to simplify working with features of Firebase Authentication by enforcing modern authentication workflows.
                       DESC
  s.homepage         = 'https://github.com/cgossain/FirebaseIdentity'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cgossain' => 'cgossain@gmail.com' }
  s.source           = { :git => 'https://github.com/cgossain/FirebaseIdentity.git', :tag => s.version.to_s }
  s.swift_version    = '5.0'
  s.static_framework = true
  s.ios.deployment_target = '12.4'
  
  s.source_files = 'FirebaseIdentity/Classes/**/*'
  s.resource_bundles = {
      'FirebaseIdentity-Assets' => ['MooveFitCoreKit/Assets/**/*']
  }
  
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Database'
  s.dependency 'ProcedureKit'
end
