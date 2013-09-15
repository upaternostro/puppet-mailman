# == Class: mailman::params
#
# This class is used to setup reasonable defaults for the essential parameters
# of a Mailman configuration.
#
# Unfortunately, Puppet manifests make it impossible to define parameters that
# have default values which derive from other parameters to the same class.
# The best workaround is to extract this logic into a "params" class and make
# other classes inherit from this one to be sure that all of these variables
# are realized. To have parameter defaults derive from other parameters more
# than one layer deep, you need to use multiple layers of inheritance. I try
# to keep it simple here, and only use one layer.
#
# To make things even more complicated, some distributions (especially RedHat)
# have changed defaults and added new variables toward the goal of being
# FHS compliant. http://wiki.list.org/pages/viewpage.action?pageId=8486957
#
# === Examples
#
# include mailman::params
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::params {
  case $::osfamily {
    'RedHat': {
      $prefix        = '/usr/lib/mailman'
      $exec_prefix   = $prefix
      $var_prefix    = '/var/lib/mailman'

      $list_data_dir = "${var_prefix}/lists"
      $log_dir       = '/var/log/mailman'
      $lock_dir      = '/var/lock/mailman'
      $config_dir    = '/etc/mailman' # Unique to RedHat packages
      $data_dir      = "${var_prefix}/data"
      $pid_dir       = '/var/run/mailman' # Unique to RedHat packages
      $spam_dir      = "${var_prefix}/spam"
      $wrapper_dir   = "${exec_prefix}/mail"
      $bin_dir       = "${prefix}/bin"
      $scripts_dir   = "${prefix}/scripts"
      $template_dir  = "${prefix}/templates" # FIXME wrong in Fedora 19
        #F19: TEMPLATE_DIR    = '/etc/mailman/templates'
      $messages_dir  = "${prefix}/messages"
      # archive_dir is not a real Mailman param, it's just useful in this module
      $archive_dir   = "${var_prefix}/archives"
      $queue_dir     = '/var/spool/mailman'

      # Other useful files
      $pid_file      = "${pid_dir}/master-qrunner.pid"
    }
    # Debian sticks to the standard much more closely
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }
}
