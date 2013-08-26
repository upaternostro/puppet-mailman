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
# === Parameters
#
# [*prefix*]
# The most important variable in a Mailman installation is prefix, because so
# many other variables derive from it. Traditionally the prefix would be set
# during compilation according to where you want the files located, but modern
# packages all use the same FHS-compliant path.
#
# [*exec_prefix*]
# Since the default for exec_prefix is to be exactly the same as prefix, I think
# this might be a legacy holdover from older versions of Mailman.
#
# [*var_prefix*]
# Changing var_prefix is the fastest way to relocate all of your site-specific
# data including mailing list configuration and archives. Typically if you are
# changing var_prefix, you may also want to change queue_dir in the init class.
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
class mailman::params (
  $prefix          = '/usr/lib/mailman',
  $exec_prefix     = '/usr/lib/mailman',
  $var_prefix      = '/var/lib/mailman',
) {
  validate_re($exec_prefix, "^${prefix}")
  $list_data_dir   = "${var_prefix}/lists"
  $data_dir        = "${var_prefix}/data"
  $spam_dir        = "${var_prefix}/spam"
  $wrapper_dir     = "${exec_prefix}/mail"
  $bin_dir         = "${prefix}/bin"
  $scripts_dir     = "${prefix}/scripts"
  $template_dir    = "${prefix}/templates"
  $messages_dir    = "${prefix}/messages"
  # archive_dir is not a real Mailman param, it's just useful in this module
  $archive_dir    = "${var_prefix}/archives"

  case $::osfamily {
    'RedHat': {
      $log_dir         = '/var/log/mailman'
      $lock_dir        = '/var/lock/mailman'
      $config_dir      = '/etc/mailman'
      $site_pw_file    = "${config_dir}/adm.pw"
      $creator_pw_file = "${config_dir}/creator.pw"
      $pid_dir         = '/var/run/mailman'
      $pid_file        = "${pid_dir}/master-qrunner.pid"
      $queue_dir       = '/var/spool/mailman'
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }
}
