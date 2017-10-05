# Apache VHost Wrapper
define host_railsapp::vhost::apache (
$basedir,
$ruby_gemset,
$options       = {},
$app_env       = undef,
$server_name   = $::fqdn,
$serveraliases = undef,
$ssl_cert      = undef,
$ssl_key       = undef,
$ssl_chain     = undef,
$vhost_type    = undef,
$vhost_options = {},
$http_port     = 80,
$https_port    = 443,
$asset_cache   = true,
$cable_path    = undef,
) {

  # Standard Capistrano Directories
  $docroot_dir  = "${basedir}/current/public"
  $releases_dir = "${basedir}/releases"

  $directories = [
    {
      path           => '/',
      require        => 'all denied',
      options        => 'SymLinksIfOwnerMatch',
      allow_override => 'None',
    },
    {
      path           => $basedir,
      require        => 'all denied',
      options        => 'SymLinksIfOwnerMatch',
      allow_override => 'None',
    },
    {
      path           => $releases_dir,
      require        => 'all granted',
      options        => 'SymLinksIfOwnerMatch',
      allow_override => 'All',
    },
    {
      path           => $docroot_dir,
      require        => 'all granted',
      options        => ['+SymLinksIfOwnerMatch','-MultiViews'],
      allow_override => 'All',
    },
  ]

# TODO: cable_path and asset_cache

  $common_vhost_options = {
    servername          => $server_name,
    serveraliases       => $serveraliases,
    serveradmin         => 'support@example.com',
    docroot             => $docroot_dir,
    manage_docroot      => false,
    directories         => $directories,
    passenger_app_env   => $app_env,
    passenger_ruby      => "/usr/local/rvm/wrappers/${ruby_gemset}/ruby"
  }

  $_vhost_options = merge($common_vhost_options, $vhost_options)

  if $http_port {
    ensure_resource( apache::vhost, "${name}-http",
      merge($_vhost_options, {
        port => $http_port,
      })
    )}

  if ($https_port and $ssl_cert and $ssl_key) {
    ensure_resource( apache::vhost, "${name}-https",
      merge($_vhost_options, {
        port      => $https_port,
        ssl       => true,
        ssl_cert  => $ssl_cert,
        ssl_key   => $ssl_key,
        ssl_chain => $ssl_chain,
      })
    )}
}
