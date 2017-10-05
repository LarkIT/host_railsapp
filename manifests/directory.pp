# Type: host_railsapp::directory
# Purpose: Handles the creation of a directory with SELinux settings and
#   filesystem ACL to allow the web server to read or write to it based on the
#   (web_rw) boolean.
#
# Parameters -
#  - namevar - directory name
#  - ensure - [directory] - (passed to ensure on file resource)
# (other "file" parameters, see below)
#  - seltype - undef - selinux type (default is the system default)
#  - web_rw - (boolean) - [false] - to allow read/write access to web group
#  - web_group - (string) - [$host_railsapp::webgroup] - the group to grant access to
#
define host_railsapp::directory (
  $ensure    = 'directory',
  $path      = $name,
  $owner     = 'root',
  $group     = 'root',
  $mode      = $host_railsapp::default_app_dir_permissions,
  $seltype   = undef,
  $web_rw    = false,
  $web_group = $host_railsapp::web_group,
) {

  $selinux_ro_context = 'httpd_sys_content_t'
  $selinux_rw_context = 'httpd_sys_rw_content_t'

  # Handle SELINUX Settings
  if str2bool($::selinux) {
    if $seltype { # Allow override
      $_seltype = $seltype
    } else {
      if $web_rw {
        $_seltype = $selinux_rw_context
      } else {
        $_seltype = $selinux_ro_context
      }
    }

    # Create FCONTEXT
    ensure_resource( 'selinux::fcontext', "${path}(/.*)?", {
      pathname            => "${path}(/.*)?",
      context             => $_seltype,
      restorecond_path    => $path,
      restorecond_recurse => true,
      before              => File[$path],
    })
  } else {
      $_seltype = undef
  }

  # CREATE the directory
  ## NOTE: overriding $mode because "group" permissions mask the fACL
  ensure_resource('file', $path, {
    ensure  => $ensure,
    owner   => $owner,
    group   => $group,
    mode    => '0770',
    seltype => $_seltype,
  })

  # Handle the Filesystem ACLs
  if $web_rw {
    $web_perms = 'rwX'
  } else {
    $web_perms = 'rX'
  }
  fooacl::conf { $path:
    permissions => [
      "group:${group}:rwX",
      #"default:group:${group}:rwX",
      "group:${web_group}:${web_perms}",
      #"default:group:${web_group}:${web_perms}",
      'mask:rwX',
    ],
    require     => File[$path],
  }
}
