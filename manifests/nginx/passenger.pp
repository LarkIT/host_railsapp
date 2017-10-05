#
# Class: host_railsapp::passenger::nginx
# Purpose: Sets up passenger on nginx using RVM
#
# NOTE: This was originally copied from the "rvm::passenger::apache" back around rvm 1.1.5
# .. which I have recently made some updates to based on 1.4.1, but its probably still bad :)
#
class host_railsapp::nginx::passenger(
  $ruby_version       = $host_railsapp::main_ruby_version,
  $passenger_version  = $host_railsapp::passenger_version,
  $rvm_prefix         = $host_railsapp::params::rvm_prefix,
  $nginx_prefix       = $host_railsapp::params::nginx_prefix,
  $ssl_dir            = $host_railsapp::params::ssl_dir,
  $nginx_conf_d       = $host_railsapp::params::nginx_conf_d,
  $mininstances       = '1',
  $maxpoolsize        = '6',
  $poolidletime       = '0',
  $maxinstancesperapp = '0',
  $spawnmethod        = 'smart-lv2',
) {
  notice("RailsApp: Nginx/Passenger - Ruby: ${ruby_version} / Passenger: ${passenger_version}")

  class { '::rvm::passenger::gem':
    ruby_version => $ruby_version,
    version      => $passenger_version,
  }
  class { '::rvm::passenger::dependencies': }

  user { 'nginx':
    ensure  => 'present',
    shell   => '/sbin/nologin',
    gid     => 'nginx',
    home    => '/opt/nginx',
    system  => true,
    require => Group['nginx'],
  }

  group { 'nginx':
    ensure => 'present',
    system => true,
  }

  $rvm = "${rvm_prefix}/bin/rvm"
  $passenger_module = "${ruby_version}/gems/passenger-${passenger_version}"

  exec { 'passenger-install-nginx-module':
    command     => "${rvm} ${ruby_version} exec passenger-install-nginx-module --auto --auto-download --prefix=${nginx_prefix}",
    environment => 'HOME=/root',
    provider    => shell,
    unless      => "[ -x ${nginx_prefix}/sbin/nginx ] && ${nginx_prefix}/sbin/nginx -V 2>&1 | grep -q ${passenger_module}",
    logoutput   => 'on_failure',
    require     => [ Class['rvm::passenger::gem'], Class['rvm::passenger::dependencies'] ],
    subscribe   => [ Class['rvm::passenger::gem'], Rvm_system_ruby[$ruby_version] ],
  }

  # Configure nginx
  # Template uses:
  #   $nginx_prefix
  file { "${nginx_prefix}/conf/nginx.conf":
    ensure    => file,
    content   => template('host_railsapp/passenger-nginx.conf.erb'),
    owner     => 'root',
    group     => 'root',
    mode      => '0700',
    require   => Exec['passenger-install-nginx-module'],
    subscribe => Exec['passenger-install-nginx-module'],
  }

  file { $nginx_conf_d:
    ensure  => directory,
    owner   => 'root',
    group   => 'nginx',
    mode    => '0740',
    purge   => true,
    recurse => true,
    require => Exec['passenger-install-nginx-module'],
  }

  file { $ssl_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    purge   => true,
    recurse => true,
    require => Exec['passenger-install-nginx-module'],
  }

  # Template uses
  #   $rvm_prefix
  #   $passenger_module
  #   $ruby_version
  #   $maxpoolsize
  #   $poolidletime
  #   $maxinstancesperapp
  #   $mininstances
  #   $spawnmethod
  file { '/etc/init.d/nginx':
    ensure  => file,
    content => template('host_railsapp/passenger-nginx.init.centos.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => Exec['passenger-install-nginx-module'],
  }

}
