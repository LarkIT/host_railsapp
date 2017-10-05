#
# Class: host_railsapp::passenger::apache
# Purpose: Wrapper class to set up passenger on apache using puppetlabs-apache
#
class host_railsapp::passenger::apache(
  $apache_mod_passenger_config = {},
) {
  include ::apache
  include ::apache::mod::passenger
  #  class {'::apache::mod::passenger':
    #    * => $apache_mod_passenger_config
    #  }

  #SELinux configuration
  if str2bool($::selinux) {
    if !defined(Selboolean['httpd_can_network_connect']) {
      selboolean { 'httpd_can_network_connect':
        persistent => true,
        value      => on,
      }
    }
  }
}
