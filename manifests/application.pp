#
# Class: host_railsapp::application
# Purpose: Creates a customer / application hosting directory and the requisite rails_environments.
#
define host_railsapp::application (
  $application              = $name,
  $application_dir          = "${host_railsapp::webroot_dir}/${name}",
  $username                 = $name,
  $groupname                = $name,
  $user_home_dir            = undef,
  $ssh_keys                 = {},
  $default_ruby_version     = $host_railsapp::main_ruby_version,
  $rails_environments       = $host_railsapp::default_rails_environments,
  $app_dir_permissions      = $host_railsapp::default_app_dir_permissions,
  $app_dir_seltype          = $host_railsapp::default_app_dir_seltype,
  $cable_path               = $host_railsapp::default_app_cable_path,
  $secrets                  = $host_railsapp::default_secrets,
  $database_hostname        = $host_railsapp::default_database_hostname,
  $database_config          = $host_railsapp::default_database_config,
  $manage_ssh_keys          = $host_railsapp::default_app_manage_ssh_keys,
  $purge_ssh_keys           = $host_railsapp::default_app_purge_ssh_keys,
  $hiera_ssh_keys           = $host_railsapp::default_app_hiera_ssh_keys,
  $ssl_cert                 = $host_railsapp::default_ssl_cert,
  $ssl_key                  = $host_railsapp::default_ssl_key,
  $ssl_chain                = $host_railsapp::default_ssl_chain,
  $vhost_options            = $host_railsapp::default_vhost_options,
  $domain_name              = $host_railsapp::default_domain_name,
  $use_asset_cache          = $host_railsapp::default_use_asset_cache,
  $http_port                = 80,
  $https_port               = 443,
) {
  notice("*host_railsapp* ${application} dir: ${application_dir} (${user_home_dir})")

  # Validation
  # -- TODO: This needs work, strings should be validated better, integers (ports), etc
  validate_string($application)
  validate_string($application_dir)
  validate_string($username)
  validate_string($groupname)
  validate_string($user_home_dir)
  validate_hash($ssh_keys)
  validate_string($default_ruby_version)
  # validate rails_environments (string, list, hash)
  validate_string($app_dir_permissions)
  validate_string($database_hostname)
  validate_hash($database_config)
  validate_bool($manage_ssh_keys)
  validate_bool($purge_ssh_keys)
  #validate_integer($http_port)
  #validate_integer($https_port)

  # Other Defaults (probably need refactored a bit)
  if $user_home_dir == undef {
    $_user_home_dir = $application_dir
  } else {
    $_user_home_dir = $user_home_dir
  }
  $gemrc_file = "${_user_home_dir}/.gemrc"

  if is_hash($rails_environments) {
    $app_environment_count = count(keys($rails_environments))
  } else {
    $app_environment_count = count($rails_environments)
  }

  # Ensure the user is created
  ensure_resource('user', $username, {
    ensure         => present,
    home           => $_user_home_dir,
    managehome     => true,
    groups         => $host_railsapp::webapp_group,
    purge_ssh_keys => $purge_ssh_keys,
  })

  # Manage the Home/App Directory directly so that auto-depends work
  # NOTE: These are usually the same directory.
  if $_user_home_dir != $application_dir {
    file { $_user_home_dir:
      ensure => 'directory',
      owner  => $username,
      group  => $groupname,
    }
  }

  file { $application_dir:
    ensure  => 'directory',
    owner   => $username,
    group   => $groupname,
    mode    => $app_dir_permissions,
    seltype => $app_dir_seltype,
  }

  # Setup default .gemrc to optimize gem installations
  ensure_resource(file, $gemrc_file, {
    ensure  => file,
    source  => 'puppet:///modules/host_railsapp/default.gemrc',
    replace => false,
    mode    => '0640',
    owner   => $username,
    group   => $groupname,
  })

  # Until we figure out user gemsets, application users must be part of the RVM group
  # Lets use the RVM function to manage that incase the "rvm" group would ever change.
  ensure_resource(rvm::system_user, $username, {
    require => User[$username],
    create  => false,
  })

  # Default Rails Env settings
  $default_rails_env_settings = {
    ruby_version    => $default_ruby_version,
    secrets         => $secrets,
    application_dir => $application_dir,
    app_env_dir_permissions => $app_dir_permissions,
    app_env_dir_seltype     => $app_dir_seltype,
    app_environment_count   => $app_environment_count,
    cable_path      => $cable_path,
    username        => $username,
    groupname       => $groupname,
    domain_name     => $domain_name,
    ssl_cert        => $ssl_cert,
    ssl_key         => $ssl_key,
    ssl_chain       => $ssl_chain,
    vhost_options   => $vhost_options,
    http_port       => $http_port,
    https_port      => $https_port,
    use_asset_cache => $use_asset_cache,
    database_config => $database_config,
    require         => File[$application_dir],
  }

  # Create requested rails deployment environments - prefix application for uniqueness
  $_application_rails_environments = prefix($rails_environments, "${application}-")
  if is_hash($_application_rails_environments) {
    create_resources( 'host_railsapp::rails_environment',
      $_application_rails_environments, $default_rails_env_settings)
  } else {
    ensure_resource( 'host_railsapp::rails_environment',
      $_application_rails_environments, $default_rails_env_settings)
  }

  if ($manage_ssh_keys) {
    # Ensure .ssh/authorized_keys is correct (this is silly)
    $dot_ssh_dir = "${_user_home_dir}/.ssh"
    $ssh_authorized_keys = "${dot_ssh_dir}/authorized_keys"

    ensure_resource(file, $dot_ssh_dir, {
      ensure  => directory,
      mode    => '0700',
      owner   => $username,
      group   => $groupname,
      seltype => 'ssh_home_t',
    })

    # SSH Keys
    if $hiera_ssh_keys {
      $_ssh_keys = merge($host_railsapp::global_ssh_keys,
        merge(hiera_hash($hiera_ssh_keys, {}), $ssh_keys))
    } else {
      $_ssh_keys = merge($host_railsapp::global_ssh_keys, $ssh_keys)
    }

    host_railsapp::sshkeys{"${username}-${application}":
      user => $username,
      keys => $_ssh_keys,
    }

    # This only seems to work *after* SSH Keys?
    ensure_resource(file, $ssh_authorized_keys, {
      ensure  => file,
      mode    => '0600',
      owner   => $username,
      group   => $groupname,
      seltype => 'ssh_home_t',
      require => Host_railsapp::Sshkeys["${username}-${application}"]
    })

  }
}
