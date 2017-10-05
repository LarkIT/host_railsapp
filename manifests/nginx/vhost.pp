#
# Class: host_railsapp::nginx::vhost
# Purpose: Defined Type to setup vhosts
#
define host_railsapp::nginx::vhost (
  $rails_env         = undef,
  $ruby_gemset       = undef,
  $approot           = undef,
  $server_name       = $name,
  $rvm_prefix        = $host_railsapp::params::rvm_prefix,
  $access_log        = undef,
  $error_log         = undef,
  $docroot           = undef,
  $logdir            = '/var/log/nginx',
  $server_port       = 80,
  $ssl_server_port   = 443,
  $passenger_enabled = 'on',
  $asset_cache       = true,
  $gzip_enabled      = 'on',
  $environments      = ['development', 'staging', 'production'],
  $cable_path        = undef,
  $nginx_conf_d      = $host_railsapp::params::nginx_conf_d,
  $ssl_dir           = $host_railsapp::params::ssl_dir,
  $server_type       = 'nginx',
  $ssl_cert          = undef,
  $ssl_key           = undef,
  $dh_size           = '2048',
  $vhost_options     = {},
  $vhost_priority    = 10,
) {

  if $docroot and $passenger_enabled == 'on' {
    $_docroot = $docroot
  } elsif $passenger_enabled == 'on' {
    if ! $approot {
      fail("host_railsapp::${name}: Either 'docroot' or 'approot' must be specified")
    }
    $_docroot = "${approot}/current/public"
  } else {
    $_docroot = false
  }

  if $passenger_enabled == 'on' {
    if ! $ruby_gemset {
      fail("host_railsapp::${name}: 'ruby_gemset' is required when passenger_enabled = 'on'")
    }
    if ! $rails_env {
      fail("host_railsapp::${name}: 'rails_env' is required when passenger_enabled = 'on'")
    }
  }

  # VHOST Config File
  #   $access_log
  #   $asset_cache
  #   $auth_basic
  #   $auth_file
  #   $auth_realm
  #   $docroot
  #   $error_log
  #   $gzip_enabled
  #   $logdir
  #   $name
  #   $passenger_enabled
  #   $rails_env
  #   $ruby_gemset
  #   $rvm_prefix
  #   $server_name
  #   $server_port
  #   $ssl_cert
  #   $ssl_dir
  #   $ssl_key
  #   $ssl_server_port
  #   $vhost_options
  # - $cable_path
  file { "${nginx_conf_d}/vhost-${vhost_priority}-${name}.conf":
    content => template('host_railsapp/nginx-vhost.erb'),
    mode    => '0640',
    owner   => 'root',
    group   => 'nginx',
    notify  => Class['host_railsapp::nginx::service'],
    require => Class['host_railsapp::nginx::passenger'],
  }

  # SSL Files
  if ($ssl_cert != undef and $ssl_key != undef) {
    file { "${ssl_dir}/${name}.crt":
      ensure  => file,
      content => $ssl_cert,
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      notify  => Class['host_railsapp::nginx::service'],
    }
    file { "${ssl_dir}/${name}.key":
      ensure  => file,
      content => $ssl_key,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      notify  => Class['host_railsapp::nginx::service'],
    }
  }
  # Ensure we use strong Diffie-Hellman parameters
  exec { "/bin/openssl dhparam -out dhparam.pem ${dh_size}":
    cwd     => $ssl_dir,
    creates => "${ssl_dir}/dhparam.pem",
    notify  => Class['host_railsapp::nginx::service'],
  }

  file { "${ssl_dir}/dhparam.pem":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    notify => Exec["/bin/openssl dhparam -out dhparam.pem ${dh_size}"],
  }

  # LOGS
  ensure_resource('file', $logdir, {
    ensure => directory,
    owner  => 'nginx',
    group  => 'nginx',
    mode   => '0755',
    before  => Class['host_railsapp::nginx::service'],
  })

}
