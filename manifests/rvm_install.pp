#
# Class: host_railsapp::rvm_install
# Purpose: This class installs rvm ins installed
#
class host_railsapp::rvm_install (
  $main_ruby_version = $::host_railsapp::main_ruby_version,
  $default_rails_version = $::host_railsapp::default_rails_version,
){
  # Ensure main_ruby_version is installed
  if !defined(Rvm_system_ruby[$main_ruby_version]) {
    rvm_system_ruby { $main_ruby_version:
      ensure    => present,
      proxy_url => $rvm::proxy_url,
      no_proxy  => $rvm::no_proxy,
    }
  }

  # Install default_rails_version (globally)
  ensure_resource( 'rvm_gem', 'rails', {
    ruby_version => "${main_ruby_version}@global",
    ensure       => $default_rails_version,
    require      => Rvm_system_ruby[$main_ruby_version],
    proxy_url    => $rvm::proxy_url,
  })

}
