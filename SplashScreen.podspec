require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

# Detect if lottie-react-native is installed in the consuming app.
# In a monorepo/workspace, lottie-react-native may be in the app's
# node_modules (not the library's). We search from the Podfile directory
# which is always inside the consuming app's ios/ folder.
lottie_found = false
begin
  # Pod::Config.instance.installation_root is the dir containing the Podfile
  app_ios_dir = Pod::Config.instance.installation_root.to_s
  result = Pod::Executable.execute_command('node', ['-e',
    "try { require.resolve('lottie-react-native/package.json', " \
    "{ paths: ['#{app_ios_dir}', '#{app_ios_dir}/..'] }); " \
    "console.log('found'); } catch(e) { console.log('notfound'); }"
  ]).strip
  lottie_found = (result == 'found')
rescue => e
  lottie_found = false
end

Pod::Spec.new do |s|
  s.name         = "SplashScreen"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/huynq1175/react-native-splash-screen.git", :tag => "#{s.version}" }

  s.source_files = [
    "ios/**/*.{swift}",
    "ios/**/*.{m,mm}",
    "cpp/**/*.{hpp,cpp}",
  ]

  s.dependency 'React-jsi'
  s.dependency 'React-callinvoker'

  # ── Optional Lottie support ──
  if lottie_found
    Pod::UI.puts "[SplashScreen] lottie-react-native detected — enabling Lottie animation support"
    s.dependency 'lottie-ios'
    s.pod_target_xcconfig = {
      'OTHER_SWIFT_FLAGS' => '$(inherited) -DLOTTIE_INSTALLED'
    }
  else
    Pod::UI.puts "[SplashScreen] lottie-react-native not found — Lottie animation support disabled"
  end

  load 'nitrogen/generated/ios/SplashScreen+autolinking.rb'
  add_nitrogen_files(s)

  install_modules_dependencies(s)
end
