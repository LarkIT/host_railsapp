#
# Class: host_railsapp::nginx::service
# Purpose: Manage the nginx service
#
class host_railsapp::nginx::service {
  service { 'nginx':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
  }
}
