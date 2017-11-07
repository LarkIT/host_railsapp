#
# Class: host_railsapp::params
# Purpose: This module provides defaults for host_railsapp
#
class host_railsapp::params {
  $main_ruby_version = 'ruby-2.4.0'
  $passenger_version = '5.1.2'
  $global_ssh_keys   = {}
  $applications      = {}
  $webapp_group      = 'webapp'


  # Rails Application Settings
  $app_settings = {}

  # Vagrant Overrides
  $app_settings_vagrant = {
    'username'        => 'vagrant',
    'groupname'       => 'vagrant',
    'user_home_dir'   => '/home/vagrant',
    'manage_ssh_keys' => false,
    'purge_ssh_keys'  => false,
  }

  # Detect Vagrant (by looking for $::vagrant fact)
  if $::vagrant == '1' {
    $default_app_settings = merge($app_settings, $app_settings_vagrant)
  } else {
    $default_app_settings = $app_settings
  }

  $default_secrets = undef
  $default_rails_version = '4.1.1'
#  $default_rails_environments = ['development', 'staging', 'production']
  $default_rails_environments = [ $trusted['extensions']['pp_environment'] ]
  $default_database_hostname = '127.0.0.1'
  $default_database_config = {
    'production' => {
      'database' => 'db/production.sqlite3',
      'adapter' => 'sqlite3',
      'pool' => 5,
      'timeout' => 5000,
    },
    'staging' => {
      'database' => 'db/staging.sqlite3',
      'adapter' => 'sqlite3',
      'pool' => 5,
      'timeout' => 5000,
    },
    'development' => {
      'database' => 'db/development.sqlite3',
      'adapter' => 'sqlite3',
      'pool' => 5,
      'timeout' => 5000,
    },
    'test' => {
      'database' => 'db/test.sqlite3',
      'adapter' => 'sqlite3',
      'pool' => 5,
      'timeout' => 5000,
    },
  }
  $default_app_dir_permissions = '0711'

  $default_app_manage_ssh_keys = true
  $default_app_purge_ssh_keys = true
  $default_app_hiera_ssh_keys = undef
  $default_app_cable_path = undef
  $default_app_dir_seltype        = 'user_home_dir_t'
  $default_app_dotssh_dir_seltype = 'ssh_home_t'

  $default_ssl_cert  = undef
  $default_ssl_key   = undef
  $default_ssl_chain = undef

  $default_domain_name   = $::fqdn
  $default_vhost_options = {}
  $default_use_asset_cache = true

  # WebRoot Specific Parameters
  # - NOTE: selinux parameters are CentOS 7 specific for now
  $webroot_dir = '/web'
  $webroot_dir_permissions = '0711'
  $webroot_dir_seltype     = 'sysfs_t'

  $webserver = 'nginx-legacy'
  $appserver = 'passenger'

  ## NGINX Parameters
  $rvm_prefix   = '/usr/local/rvm'
  $nginx_prefix = '/opt/nginx'
  $ssl_dir = "${nginx_prefix}/ssl"
  $nginx_conf_d = "${nginx_prefix}/conf/conf.d"

}
