# == Class: mailman
#
# This class sets up a minimal Mailman environment, but does not provide any
# integration with mail transfer agents or web servers. Typically you would
# also want to use mailman::postfix and mailman::apache.
#
# It is assumed that the operating system provides Mailman packages, and that
# the compiled version is >= 2.1.5. The paths used by Mailman became compliant
# with the Filesystem Hierarchy Standard in 2.1.5.
#
# NOTE: Don't bother using the "check_perms" binary on RedHat systems. The
# RedHat packages have intentionally customized permissions for security.
#  https://bugzilla.redhat.com/show_bug.cgi?id=701539
#
# === Parameters
#
# Originally I wanted to use native Python path joins exactly the same
# as is done in Defaults.py. However, it is useful to have all of the
# paths fully resolved in the Puppet manifest so they can be used with
# file resources. Still, I try to track Defaults.py wherever possible.
#
# [*MTA*]
#   The MTA param names a module in the Mailman/MTA dir which contains the mail
#   server-specific functions to be executed when a list is created or removed.
#
# [*virtual_host_overview*]
#   We want the web interface to display lists even when teh URL does not
#   match, which makes it easier to test web interfaces on several servers
#
# === Examples
#
#  include mailman
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman (
  $site_pw,
  $activate_qrunners = false,

  $language            = 'en',
  $mailman_site_list   = 'mailman',
  $mta                 = 'Manual',
  $smtp_hostname       = $hostname,
  $http_hostname       = $hostname,
  $default_url_pattern = 'http://%s/mailman/',

  $list_data_dir   = $mailman::params::list_data_dir,
  $log_dir         = $mailman::params::log_dir,
  $lock_dir        = $mailman::params::lock_dir,
  $config_dir      = $mailman::params::config_dir,
  $data_dir        = $mailman::params::data_dir,
  $pid_dir         = $mailman::params::pid_dir,
  $spam_dir        = $mailman::params::spam_dir,
  $wrapper_dir     = $mailman::params::wrapper_dir,
  $bin_dir         = $mailman::params::bin_dir,
  $scripts_dir     = $mailman::params::scripts_dir,
  $template_dir    = $mailman::params::template_dir,
  $messages_dir    = $mailman::params::messages_dir,
  $queue_dir       = $mailman::params::queue_dir,
  $pid_file        = $mailman::params::pid_file,
  $site_pw_file    = $mailman::params::site_pw_file,
  $creator_pw_file = $mailman::params::creator_pw_file,

  $virtual_host_overview = true,
  $smtp_max_rcpts        = '500',
) inherits mailman::params {
  $langs = ['ar','ca','cs','da','de','en','es','et','eu','fi','fr','gl','he',
    'hr','hu','ia','it','ja','ko','lt','nl','no','pl','pt','pt_BR','ro',
    'ru','sk','sl','sr','sv','tr','uk','vi','zh_CN','zh_TW']
  validate_bool($activate_qrunners)
  validate_re($language, $langs)
  validate_re($mailman_site_list, '[-+_.=a-z0-9]*')
  validate_re($mta, ['Manual', 'Postfix'])
  validate_bool($virtual_host_overview)
  validate_re($smtp_max_rcpts, '[0-9]*')

  # These are local variables instead of parameters because it would not make
  # sense to override them. Prefix and Var_prefix are the basis of many other
  # variables, and overriding them would be counter-intuitive.
  $prefix          = $mailman::params::prefix
  $var_prefix      = $mailman::params::var_prefix

  # Archive directories are shared with Apache module by extracting them
  # into params. TODO: maybe pull them back out of params and have apache
  # module refer to this class directly?
  $private_archive_file_dir = $mailman::params::private_archive_file_dir
  $public_archive_file_dir  = $mailman::params::public_archive_file_dir

  # Since this variable is reused by Apache class, it needed a better name
  # than default_url_host.
  $default_email_host  = $smtp_hostname
  $default_url_host    = $http_hostname

  $site_pw_hash = sha1($site_pw)

  package { 'mailman':
    ensure  => installed,
  }

  # Config file is built using concat so other classes can contribute.
  # Must declare concat before any concat::fragment resources.
  concat { 'mm_cfg':
    path    => "${prefix}/Mailman/mm_cfg.py",
    owner   => 'root',
    group   => 'mailman',
    mode    => '0644',
    require => Package['mailman'],
  }
  concat::fragment { 'mm_cfg_top':
    content => template("${module_name}/mm_cfg.py.erb"),
    target  => 'mm_cfg',
    order   => '00',
  }
  include mailman::options

  # Create files with a SHA1 hash of the site_pw (basically a skeleton key)
  file { [$site_pw_file, $creator_pw_file]:
    ensure  => present,
    content => "$site_pw_hash\n",
    owner   => 'root',
    group   => 'mailman',
    mode    => '0644',
    require => Package['mailman'],
  }

  # Need to ensure that queue_dir exists, in case a custom valid is provided.
  file { $queue_dir:
    ensure  => directory,
    owner   => 'mailman',
    group   => 'mailman',
    mode    => '2770',
    require => Package['mailman'],
  }
  # If a custom value is provided for var_prefix then it needs to be created.
  file { $var_prefix:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2775',
    require => Package['mailman'],
  }
  file { $list_data_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2775',
    require => File[$var_prefix],
  }
  # TODO: maybe need to create other directories too?

  # If the site list doesn't exist already, then it is created and the
  # password is immediately reset.
  exec { 'create_site_list':
    command => "newlist --quiet '${mailman_site_list}' '${mailman_site_list}@${default_email_host}' 'CHANGEME'",
    path    => $bin_dir,
    creates => "${list_data_dir}/${mailman_site_list}/config.pck",
    require => [ File[$list_data_dir], Concat['mm_cfg'] ],
    notify  => Exec['change_site_list_pw'],
  }
  exec { 'change_site_list_pw':
    command     => "change_pw -l '${mailman_site_list}'"
    path        => $bin_dir,
    refreshonly => true,
  }

  service { 'mailman':
    ensure  => $activate_qrunners,
    enable  => $activate_qrunners,
    require => Exec['create_site_list'],
  }
}
