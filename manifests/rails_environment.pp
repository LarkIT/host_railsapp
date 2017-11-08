#
# Class: host_railsapp::rails_environment
# Purpose: Creates a rails_environment for an application.
#
# Parameters -
# - namevar - should be "application-rails_env" to allow name based parsing
# - rails_env_override - to override "name parsed" rails_env
# - application_dir - directory in which the rails_env directory should be created
# - ruby_version - full rvm version of ruby (example: 'ruby-2.0.0-p353')
# - gemset_name - name of the gemset to create (defaults to $name)
# - username - owner of the created files/directories
# - groupname - group on the created files/directories
# - servername - hostname of webserver (mostly for multiple apps)
# - ssl_cert - ssl certificate passed to vhost
# - ssl_key - ssl key passed to vhost
# - vhost_options - options hash passed directly to vhost
# - http_port - HTTP Port to host rails_env
# - https_port - HTTPS Port to host rails_env
# - use_asset_cache - boolean - whether or not to enable asset cache settings in 
#
# TODO:
# - Do we want to deal with GEM installation?
# - User Gemsets? (future)
define host_railsapp::rails_environment (
  $rails_env_override = undef,
  $application_dir    = undef,
  $app_env_dir_permissions = undef,
  $app_env_dir_seltype     = undef,
  $app_environment_count = 0,
  $cable_path         = undef,
  $ruby_version       = $host_railsapp::main_ruby_version,
  $gemset_name        = $name,
  $username           = undef,
  $groupname          = undef,
  $domain_name        = undef,
  $server_name        = undef,
  $serveraliases      = undef,
  $ssl_cert           = undef,
  $ssl_key            = undef,
  $ssl_chain          = undef,
  $secrets            = undef,
  $database_config    = {},
  $vhost_options      = {},
  $http_port          = 80,
  $https_port         = 443,
  $use_asset_cache    = $host_railsapp::default_use_asset_cache,
) {
  # Set rails_env based on the name, not very safe, but avoids "--parser future"
  if ($rails_env_override) {
    $rails_env = $rails_env_override
  } else {
    $rails_env = regsubst($name, '^.*\-(.*)$', '\1')
  }
  $rails_env_dir     = "${application_dir}/${rails_env}"
  $rvm_gemset        = "${ruby_version}@${gemset_name}"
  $dot_rvmrc         = "${rails_env_dir}/.rvmrc"
  $dot_rubyversion_l = "${rails_env_dir}/.ruby-version"
  $dot_rubygemset_l  = "${rails_env_dir}/.ruby-gemset"
  $shared_dir        = "${rails_env_dir}/shared"
  $docroot_dir       = "${rails_env_dir}/current/public"
  $releases_dir      = "${rails_env_dir}/releases"
  $dot_rubyversion   = "${shared_dir}/.ruby-version"
  $dot_rubygemset    = "${shared_dir}/.ruby-gemset"
  $shared_config_dir = "${shared_dir}/config"
  $shared_log_dir    = "${shared_dir}/log"
  $database_yml      = "${shared_config_dir}/database.yml"
  $secrets_yml       = "${shared_config_dir}/secrets.yml"

  notice("*DEBUG* RailsEnvDir: ${rails_env_dir} / RailsEnv: ${rails_env} / RubyGemSet: ${rvm_gemset}")

  # NOTE $application_dir is already created and is required to be readable
  # ALSO: $docroot_dir is a symlink to releases/DATESTAMP

  # Create the app_env_dir
  ensure_resource('file', $rails_env_dir, {
    ensure  => 'directory',
    owner   => $username,
    group   => $groupname,
    mode    => $app_env_dir_permissions,
    seltype => $app_env_dir_seltype,
  })

  # Capistrano RO Directories
  $ro_dirs = [
    $releases_dir,
    $shared_dir,
  ]

  ensure_resource('host_railsapp::directory', $ro_dirs, {
    owner  => $username,
    group  => $groupname,
    notify => Exec[ '/usr/local/sbin/fooacl' ],
  })

  # Capistrano RW Directories
  $rw_dirs = [
    "${shared_dir}/tmp",
    "${shared_dir}/log",
    "${shared_dir}/public",
  ]

  ensure_resource('host_railsapp::directory', $rw_dirs, {
    owner  => $username,
    group  => $groupname,
    web_rw => true,
    notify => Exec[ '/usr/local/sbin/fooacl' ],
  })

  # Handle docroot (current) as a symlink
  # TODO: allow webapp::directory to handle these links
  # Create FCONTEXT ONLY
  ensure_resource( 'selinux::fcontext', "${docroot_dir}(/.*)?", {
    pathname            => "${docroot_dir}(/.*)?",
    context             => 'httpd_sys_content_t',
    restorecond_path    => $docroot_dir,
    restorecond_recurse => false,
  })

  # Setup an Environment specific gemset
  rvm_gemset { $rvm_gemset:
    ensure  => present,
    require => Class['host_railsapp::rvm_install'],
  }

#  # Create a .rvmrc to point at the gemset
#  file { $dot_rvmrc:
#    ensure  => file,
#    mode    => '0664',
#    content => template('host_railsapp/default.rvmrc.erb'),
#    owner   => $username,
#    group   => $groupname,
#  }

  # Create the config dir
  file { $shared_config_dir:
    ensure => directory,
    owner  => $username,
    group  => $groupname,
    mode   => '0771',
  }

  # Create a .ruby-version to point at the ruby version
  file { $dot_rubyversion:
    ensure  => file,
    mode    => '0664',
    content => "${ruby_version}\n",
    owner   => $username,
    group   => $groupname,
  }

  # Create a .ruby-gemset to point at the ruby gemset:
  file { $dot_rubygemset:
    ensure  => file,
    mode    => '0664',
    content => "${gemset_name}\n",
    owner   => $username,
    group   => $groupname,
  }

  # Create a .ruby-version link to the shared ruby version
  file { $dot_rubyversion_l:
    ensure => link,
    target => $dot_rubyversion,
    owner  => $username,
    group  => $groupname,
  }

  # Create a .ruby-gemset link to shared ruby gemset:
  file { $dot_rubygemset_l:
    ensure => link,
    target => $dot_rubygemset,
    owner  => $username,
    group  => $groupname,
  }



  # Create database.yml for application
  # Template uses:
  #   $database_config
  #   $database_hostname
  #   $rails_env
  file { $database_yml:
    ensure  => file,
    #replace => false,
    mode    => '0460',
    owner   => $username,
    group   => $groupname,
    content => template('host_railsapp/database.yml.erb'),
  }

  # Template uses:
  #   $secrets
  if ($secrets != undef) {
    # Create secrets.yml for application
    file { $secrets_yml:
      ensure  => file,
      content => template('host_railsapp/secrets.yml.erb'),
      #replace => false,
      mode    => '0460',
      owner   => $username,
      group   => $groupname,
    }
  }

  # Asset Cache unless development
  $asset_cache = $rails_env ? {
    'development' => false,
    default       => $use_asset_cache,
  }

  # SSL Files
  if $ssl_cert {
    if false  and is_absolute_path($ssl_cert) and is_absolute_path($ssl_key) { # filename, assume its alerady there
      $ssl_cert_filename  = $ssl_cert
      $ssl_key_filename   = $ssl_key
      $ssl_chain_filename = $ssl_chain # its OK for this to be undef
    } elsif $ssl_cert =~ /^letsencrypt/ { # Use a generated LetsEncrypt SSL Cert
      $ssl_cert_filename  = "/etc/letsencrypt/live/${::fqdn}/cert.pem"
      $ssl_key_filename  = "/etc/letsencrypt/live/${::fqdn}/privkey.pem"
      $ssl_chain_filename  = "/etc/letsencrypt/live/${::fqdn}/chain.pem"
    } else { # Create cert file from string passed in
      $ssl_cert_filename = "/etc/pki/tls/certs/${name}.pem"
      ensure_resource('file', $ssl_cert_filename, {
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => $ssl_cert,
      })

      $ssl_key_filename = "/etc/pki/tls/private/${name}.pem"
      ensure_resource('file', $ssl_key_filename, {
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => $ssl_key,
      })

      if $ssl_chain {
        $ssl_chain_filename = "/etc/pki/tls/certs/${name}-chain.pem"
        ensure_resource('file', $ssl_chain_filename, {
          ensure  => file,
          owner   => 'root',
          group   => 'root',
          mode    => '0600',
          content => $ssl_chain,
        })
      } else {
        $ssl_chain_filename = undef
        } # ssl_chain
    } # create files from strings passed in
  } else { # ssl_cert not defined
    $ssl_cert_filename = undef
    $ssl_key_filename = undef
    $ssl_chain_filename = undef
  }

  # Automatically set server_name (if it is not set)
  if $server_name {
    $_server_name = $server_name
  } else {
    if $app_environment_count > 1 {
      case $rails_env {
        'production': {
          $_server_name = "www.${domain_name}"
        }
        default: {
          $_server_name = "${rails_env}.${domain_name}"
        }
      }
    } else {
      $_server_name = $domain_name
    }
  }

  # Create a virtualhost
  ensure_resource( "host_railsapp::vhost::${host_railsapp::webserver}", $name, {
    basedir         => $rails_env_dir,
    server_name     => $_server_name,
    serveraliases   => $serveraliases,
    ruby_gemset     => $rvm_gemset,
    app_env         => $rails_env,
    ssl_cert        => $ssl_cert_filename,
    ssl_key         => $ssl_key_filename,
    ssl_chain       => $ssl_chain_filename,
    vhost_options   => $vhost_options,
    http_port       => $http_port,
    https_port      => $https_port,
    asset_cache     => $asset_cache,
    cable_path      => $cable_path,
    require         => Rvm_gemset[$rvm_gemset],
    })

}
