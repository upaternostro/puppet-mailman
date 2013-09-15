# == Class: mailman::config
#
# This class has one job: get started building mm_cfg.py for Mailman.
# When using big templates, I like to dedicate an entire class to the purpose
# so that all manifests are clear about which variables are actually used.
#
# === Examples
#
# This is used internally by class 'mailman'. Don't reference it externally.
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::config inherits mailman::params {
  $default_url_host         = $mailman::http_hostname
  $default_email_host       = $mailman::default_email_host
  $default_url_pattern      = 'http://%s/mailman/'
  $mailman_site_list        = $mailman::mailman_site_list
  $language                 = $mailman::language
  $mta                      = $mailman::mta
  $log_dir                  = $mailman::log_dir
  $lock_dir                 = $mailman::lock_dir
  $pid_dir                  = $mailman::pid_dir
  $var_prefix               = $mailman::var_prefix
  $data_dir                 = $mailman::data_dir
  $list_data_dir            = $mailman::list_data_dir
  $config_dir               = $mailman::data_dir # Unique to RHEL
  $site_pw_file             = $mailman::site_pw_file
  $creator_pw_file          = $mailman::creator_pw_file
  $private_archive_file_dir = $mailman::private_archive_file_dir
  $public_archive_file_dir  = $mailman::public_archive_file_dir
  $queue_dir                = $mailman::queue_dir
  $virtual_host_overview    = $mailman::virtual_host_overview
  $smtp_max_rcpts           = $mailman::smtp_max_rcpts
  $prefix                   = $mailman::params::prefix
  $bin_dir                  = $mailman::params::bin_dir
  $scripts_dir              = $mailman::params::scripts_dir
  $template_dir             = $mailman::params::template_dir
  $messages_dir             = $mailman::params::messages_dir
  $wrapper_dir              = $mailman::params::wrapper_dir

  # Config file is built using concat so other classes can contribute.
  # Must declare concat before any concat::fragment resources.
  concat { 'mm_cfg':
    path    => "${prefix}/Mailman/mm_cfg.py",
    owner   => 'root',
    group   => 'mailman',
    mode    => '0644',
    require => Package['mailman'],
    notify  => Service['mailman'],
  }
  concat::fragment { 'mm_cfg_top':
    content => template("${module_name}/mm_cfg.py.erb"),
    target  => 'mm_cfg',
    order   => '00',
  }
}
