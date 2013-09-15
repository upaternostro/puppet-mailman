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
# Caution: If you use Mailman on more than one server, be careful to
# only enable the Mailman service (qrunners) on ONE server.
#
# [*MTA*]
#   The MTA param names a module in the Mailman/MTA dir which contains the mail
#   server-specific functions to be executed when a list is created or removed.
#
# [*virtual_host_overview*]
#   We want the web interface to display lists even when teh URL does not
#   match, which makes it easier to test web interfaces on several servers
#   This is a deviation from the Mailman default of "true".
#   This allows lists to show up, even if the wrong hostname is being used.
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
  $enable_service        = false,
  $site_pw               = 'CHANGEME',
  $language              = 'en',
  $mailman_site_list     = 'mailman',
  $mta                   = 'Manual',
  $smtp_hostname         = $::fqdn,
  $http_hostname         = $::hostname,
  $default_url_pattern   = 'http://%s/mailman/',
  $virtual_host_overview = false,
  $smtp_max_rcpts        = 500,
  $var_prefix            = $mailman::params::var_prefix,
  $list_data_dir         = $mailman::params::list_data_dir,
  $log_dir               = $mailman::params::log_dir,
  $lock_dir              = $mailman::params::lock_dir,
  $data_dir              = $mailman::params::data_dir,
  $pid_dir               = $mailman::params::pid_dir,
  $spam_dir              = $mailman::params::spam_dir,
  $queue_dir             = $mailman::params::queue_dir,
  $archive_dir           = $mailman::params::archive_dir,
  $pid_file              = $mailman::params::pid_file,
) inherits mailman::params {
  $langs = ['ar','ca','cs','da','de','en','es','et','eu','fi','fr','gl','he',
    'hr','hu','ia','it','ja','ko','lt','nl','no','pl','pt','pt_BR','ro',
    'ru','sk','sl','sr','sv','tr','uk','vi','zh_CN','zh_TW']
  validate_bool($enable_service)
  validate_re($language, $langs)
  validate_re($mailman_site_list, '[-+_.=a-z0-9]*')
  validate_re($mta, ['Manual', 'Postfix'])
  # Mailman insists that the mail domain MUST have 2 or more parts
  validate_re($smtp_hostname, "^[-a-zA-Z0-9]+\.[-a-zA-Z0-9\.]+$")
  validate_re($http_hostname, "^[-a-zA-Z0-9\.]+$")
  validate_bool($virtual_host_overview)
  validate_re($smtp_max_rcpts, '[0-9]*')

  # I would prefer that var_prefix cannot be customized, but on RedHat
  # the "rmlist" command explicitly depends on var_prefix. (#11) So if we
  # want rmdir to work with non-standard list data dir, then var_prefix must
  # also be customizable.
  if $var_prefix != $mailman::params::var_prefix {
    $vpmsg = "If you change var_prefix, you SHOULD change relevant subdirectories."
    notice($vpmsg)
    notify {$vpmsg:}
  }

  if $::osfamily == 'RedHat' {
    if $list_data_dir != "${var_prefix}/lists" {
      $rmlist_msg = "On RedHat systems, list_data_dir must reside in var_prefix, otherwise rmlist will fail"
      fail($rmlist_msg)
    }
  }

  # These are local variables instead of parameters because it would not make
  # sense to override them. Prefix and Var_prefix are the basis of many other
  # variables, and overriding them would be counter-intuitive.
  $prefix          = $mailman::params::prefix
  # Also static directories don't need to be relocated.
  $bin_dir         = $mailman::params::bin_dir
  $scripts_dir     = $mailman::params::scripts_dir
  $template_dir    = $mailman::params::template_dir
  $messages_dir    = $mailman::params::messages_dir
  $wrapper_dir     = $mailman::params::wrapper_dir
  #config_dir isn't standard mailman, it only exists in red hat
  #but it does need to be in the config file for redhat, for MTA postfix
  $config_dir      = $data_dir

  $site_pw_file    = "${data_dir}/adm.pw"
  $creator_pw_file = "${data_dir}/creator.pw"
  $private_archive_file_dir = "${archive_dir}/private"
  $public_archive_file_dir  = "${archive_dir}/public"
  $aliasfile       = "${data_dir}/aliases"
  $aliasfiledb     = "${data_dir}/aliases.db"

  # Since this variable is reused by Apache class, it needed a better name
  # than default_url_host.
  $default_email_host  = $smtp_hostname
  $default_url_host    = $http_hostname

  $admin_email = "${mailman_site_list}@${default_email_host}"
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
    notify  => Service['mailman'],
  }
  concat::fragment { 'mm_cfg_top':
    content => template("${module_name}/mm_cfg.py.erb"),
    target  => 'mm_cfg',
    order   => '00',
  }

  # Although running genaliases seems like a helpful idea, there is a known bug
  # in Mailman prior to 2.1.15 that causes genaliases to run very slowly on
  # systems with large numbers of lists. I'm leaving this commented out for now,
  # and might bring it back later as an option, or dependent on Mailman version.
  #exec { 'genaliases':
  #  command     => 'genaliases',
  #  path        => $bin_dir,
  #  refreshonly => true,
  #  subscribe   => Concat['mm_cfg'],
  #}

  # Create files with a SHA1 hash of the site_pw (basically a skeleton key)
  file { [$site_pw_file, $creator_pw_file]:
    ensure  => present,
    content => "$site_pw_hash\n",
    owner   => 'root',
    group   => 'mailman',
    mode    => '0644',
    seltype => 'mailman_data_t',
    require => Package['mailman'],
  }

  # Need to ensure that queue_dir exists, in case a custom valid is provided.
  file { $queue_dir:
    ensure  => directory,
    owner   => 'mailman',
    group   => 'mailman',
    mode    => '2770',
    seltype => 'mailman_data_t',
    require => Package['mailman'],
  }
  file { $log_dir:
    ensure  => directory,
    owner   => 'mailman',
    group   => 'mailman',
    mode    => '2770',
    seltype => 'mailman_log_t',
    require => Package['mailman'],
  }
  file { $lock_dir:
    ensure  => directory,
    owner   => 'mailman',
    group   => 'mailman',
    mode    => '2770',
    seltype => 'mailman_lock_t',
    require => Package['mailman'],
  }
  # If a custom value is provided for var_prefix then it needs to be created.
  file { $var_prefix:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2775',
    seltype => 'mailman_data_t',
    require => Package['mailman'],
  }
  file { $data_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2775',
    seltype => 'mailman_data_t',
  }
  file { $aliasfile:
    ensure  => present,
    owner   => 'mailman',
    group   => 'apache',
    mode    => '0664',
    seltype => 'mailman_data_t',
    require => File[$data_dir],
  }
  file { $aliasfiledb:
    ensure  => present,
    owner   => 'mailman',
    group   => 'apache',
    mode    => '0664',
    seltype => 'mailman_data_t',
    require => File[$data_dir],
  }
  file { $list_data_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2775',
    seltype => 'mailman_data_t',
    require => File[$var_prefix],
  }
  file { $archive_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2775',
    seltype => 'mailman_archive_t',
  }
  file { $private_archive_file_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2771',
    seltype => 'mailman_archive_t',
    require => File[$archive_dir],
  }
  file { $public_archive_file_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2775',
    seltype => 'mailman_archive_t',
    require => File[$archive_dir],
  }

  # TODO: maybe need to create other directories too?

  # Red Hat packages are customized to create files in /etc/ but this
  # module ignores that and puts everything in DATA_DIR. As a compromise,
  # we can insert symlinks to make RedHat users happy.
  if $::osfamily == 'RedHat' {
    $etc_dir = '/etc/mailman'
    file { $etc_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'mailman',
      mode    => '2775',
      seltype => 'mailman_data_t',
    }
    file { "${etc_dir}/mm_cfg.py":
      ensure  => link,
      target  => "${prefix}/Mailman/mm_cfg.py",
      require => File[$etc_dir],
    }
    file { "${etc_dir}/adm.pw":
      ensure  => link,
      target  => $site_pw_file,
      require => File[$etc_dir],
    }
    file { "${etc_dir}/creator.pw":
      ensure  => link,
      target  => $creator_pw_file,
      require => File[$etc_dir],
    }
    file { "${etc_dir}/aliases":
      ensure  => link,
      target  => "${data_dir}/aliases",
      require => File[$etc_dir],
    }
    file { "${etc_dir}/aliases.db":
      ensure  => link,
      target  => "${data_dir}/aliases.db",
      require => File[$etc_dir],
    }
    file { "${etc_dir}/virtual-mailman":
      ensure  => link,
      target  => "${data_dir}/virtual-mailman",
      require => File[$etc_dir],
    }
  }

  # If the site list doesn't exist already, then it is created and the
  # password is immediately reset.
  exec { 'create_site_list':
    command => "newlist -q '${mailman_site_list}' '${admin_email}' 'CHANGEME'",
    path    => $bin_dir,
    creates => "${list_data_dir}/${mailman_site_list}/config.pck",
    require => [ File[$list_data_dir], Concat['mm_cfg'] ],
    notify  => Exec['change_site_list_pw'],
  }
  exec { 'change_site_list_pw':
    command     => "change_pw --quiet -l '${mailman_site_list}'",
    path        => $bin_dir,
    refreshonly => true,
  }

  service { 'mailman':
    ensure  => $enable_service,
    enable  => $enable_service,
    require => Exec['create_site_list'],
  }
}
