#
# Class: host_railsapp
# Purpose: Manages host_railsapp
#
# Parameters: (see params.pp for defaults)
# - main_ruby_version - default version of ruby, and the version that will be used for passenger
# - passenger_version - version of Phusion Passenger (specific gem version)
# - global_ssh_keys - ARRAY of SSH Public Keys that will be granted access to ALL hosted applications
#                      NOTE: SEE application::settings::ssh_keys paramteter for application specific access
# - applications - list of applications to deploy
#           (or) - HASH of application names -> { applicationparameters }
#   (alternatively you can call host_railsapp::applictaion directly
#                      NOTE: application and "customer" may be intercanged, but I am hoping to avoid confusion
#                             because one customer may want to host multiple applications.
# - default_application_settings - HASH of default application settings (passed to host_railsapp::application declarations)
# - default_app_dir_permissions - default application directory permissions (octal string)
# - default_app_dir_manage_ssh_keys = BOOLEAN - whether or not we should manage SSH keys (default true)
# - default_app_dir_purge_ssh_keys = BOOLEAN - whether or not we should purge unmanaged SSH keys (default true)
# - default_app_hiera_ssh_keys = STRING - Hiera path to query (hiera_hash) SSH keys from
# - default_app_cable_path = STRING (starting with /) - path for Rails5 Action Cable Path
# - default_rails_environments - ARRAY of rails environments that will be created by default in each application
# - default_use_asset_cache - BOOLEAN - whether or not to use asset cache settings in nginx
# - vhost_redirect - HASH of redirects.  { 'server_name' => 'destination' }
# - webroot_dir - root directory where application directories will be created
# - webroot_permissions - Web Root Directory Permissions (octal string)
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#   include host_railsapp
#
class host_railsapp (
  $main_ruby_version                = $host_railsapp::params::main_ruby_version,
  $passenger_version                = $host_railsapp::params::passenger_version,
  $global_ssh_keys                  = $host_railsapp::params::global_ssh_keys,
  $applications                     = $host_railsapp::params::applications,
  $webapp_group                     = $host_railsapp::params::webapp_group,
  $default_app_settings             = $host_railsapp::params::default_app_settings,
  $default_app_dir_permissions      = $host_railsapp::params::default_app_dir_permissions,
  $default_app_dir_seltype          = $host_railsapp::params::default_app_dir_seltype,
  $default_app_dotssh_dir_seltype   = $host_railsapp::params::default_app_dotssh_dir_seltype,
  $default_app_manage_ssh_keys      = $host_railsapp::params::default_app_manage_ssh_keys,
  $default_app_purge_ssh_keys       = $host_railsapp::params::default_app_purge_ssh_keys,
  $default_app_hiera_ssh_keys       = $host_railsapp::params::default_app_hiera_ssh_keys,
  $default_app_cable_path           = $host_railsapp::params::default_app_cable_path,
  $default_secrets                  = $host_railsapp::params::default_secrets,
  $default_rails_version            = $host_railsapp::params::default_rails_version,
  $default_rails_environments       = $host_railsapp::params::default_rails_environments,
  $default_database_hostname        = $host_railsapp::params::default_database_hostname,
  $default_database_config          = $host_railsapp::params::default_database_config,
  $default_ssl_cert                 = $host_railsapp::params::default_ssl_cert,
  $default_ssl_key                  = $host_railsapp::params::default_ssl_key,
  $default_ssl_chain                = $host_railsapp::params::default_ssl_chain,
  $default_domain_name              = $host_railsapp::params::default_domain_name,
  $default_vhost_options            = $host_railsapp::params::default_vhost_options,
  $default_use_asset_cache          = $host_railsapp::params::default_use_asset_cache,
  $vhost_redirect                   = {},
  $webroot_dir                      = $host_railsapp::params::webroot_dir,
  $webroot_dir_permissions          = $host_railsapp::params::webroot_dir_permissions,
  $webroot_dir_seltype              = $host_railsapp::params::webroot_dir_seltype,
  $webserver                        = $host_railsapp::params::webserver,
  $appserver                        = $host_railsapp::params::appserver,
  $appserver_config                 = {},
) inherits host_railsapp::params {
notify{"Nick $default_database_hostname":}
  # SELinux FContexts
  if str2bool($::selinux) {
    selinux::fcontext { $webroot_dir:
      pathname => $webroot_dir,
      context  => $webroot_dir_seltype,
      before   => File[$webroot_dir],
    }

    selinux::fcontext { "${webroot_dir}/(.*)":
      pathname            => "${webroot_dir}/(.*)",
      context             => $default_app_dir_seltype,
      restorecond_path    => "${webroot_dir}/*",
      restorecond_recurse => false, # Let's not recurse here, seems dangerous
      before              => File[$webroot_dir],
    }

    selinux::fcontext { "${webroot_dir}/[^/]+/\\.ssh(/.*)?":
      pathname            => "${webroot_dir}/[^/]+/\\.ssh(/.*)?",
      context             => $default_app_dotssh_dir_seltype,
      restorecond_path    => "${webroot_dir}/*/.ssh",
      restorecond_recurse => true,
      before              => File[$webroot_dir],
    }
  }

  # Set up RVM
  class {'::host_railsapp::rvm_install': }

  case $webserver {
    'nginx-legacy': {
      # Install Phusion Passenger / Nginx
      class {'::host_railsapp::nginx::passenger': }
      ~> class {'::host_railsapp::nginx::service': }
      $web_logdir = '/var/log/nginx'
      $web_group  = 'nginx'
      $process_mon = 'nginx: master process'
    }
    'apache': {
      class {"::host_railsapp::${appserver}::${webserver}":
        apache_mod_passenger_config => $appserver_config,
      }
      $web_logdir = '/var/log/httpd'
      $web_group = $webserver
      $process_mon = '/usr/sbin/httpd'
    }
    default: { fail("${webserver} is an unsupported webserver option (host_railsapp)") }
  }

  # System Group - for log access
  group { $webapp_group:
    ensure => present,
    system => true,
  }

  # Web Logs should be readable
  fooacl::conf { $web_logdir:
    permissions => [
      "group:${webapp_group}:rX",
      'mask:rwX',
    ],
    require     => Class[$webserver],
  }

  # Create WebRoot
  file { $webroot_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => $webroot_dir_permissions,
    seltype => $webroot_dir_seltype,
  }

  # Create any redirects offered
  $_redirect_defaults = {
    ssl_cert => $default_ssl_cert,
    ssl_key  => $default_ssl_key,
    #    notify   => Class['host_railsapp::nginx::service'],
  }

  # TODO: FIX Redirects
  #  create_resources(::host_railsapp::nginx::vhost, redirect_vhost($vhost_redirect), $_redirect_defaults )

  # Setup Applications that were defined to init.pp
  if is_hash($applications) {
    create_resources( 'host_railsapp::application', $applications,
      merge($default_app_settings, { require => File[$webroot_dir] }))
  } else {
    ensure_resource( 'host_railsapp::application', $applications,
      merge($default_app_settings, { require => File[$webroot_dir] }))
  }
}
