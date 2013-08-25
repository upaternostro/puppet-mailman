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

	$language = 'en',
	$mailman_site_list = 'mailman',
	$mta = 'Manual',
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

        $virtual_host_overview                = true,
        $smtp_max_rcpts                       = '500',
) inherits mailman::params {
	$langs = ['ar','ca','cs','da','de','en','es','et','eu','fi','fr','gl','he',
		'hr','hu','ia','it','ja','ko','lt','nl','no','pl','pt','pt_BR','ro',
		'ru','sk','sl','sr','sv','tr','uk','vi','zh_CN','zh_TW']
	validate_bool($activate_qrunners)
	validate_re($language, $langs)
	validate_re($mailman_site_list, '[-+_.=a-z0-9]*')
	# TODO: create manifest called "mailman::postfix" and use concat to load MTA settings into mm_cfg.py
	validate_re($mta, ['Manual', 'Postfix'])
        validate_bool($virtual_host_overview)
        validate_re($smtp_max_rcpts, '[0-9]*')

	$prefix          = $mailman::params::prefix
	$var_prefix      = $mailman::params::var_prefix

	$private_archive_file_dir = $mailman::params::private_archive_file_dir
	$public_archive_file_dir  = $mailman::params::public_archive_file_dir

        $default_email_host  = $smtp_hostname
        $default_url_host    = $http_hostname

	# Originally I wanted to use native Python path joins exactly the same
	# as is done in Defaults.py. However, it is useful to have all of the
	# paths fully resolved in the Puppet manifest so they can be used with
	# file resources. Still, I try to track Defaults.py wherever possible.

	# Mailman service will fail if queue_dir is unwritable or doesn't exist.
	file { $queue_dir:
		ensure => directory,
		owner  => 'mailman',
		group  => 'mailman',
		mode   => '2770',
	}

	# Mailman does not automatically create the list data dir
	file { $var_prefix:
		ensure => directory,
		owner  => 'root',
		group  => 'mailman',
		mode   => '2775',
	} -> file { $list_data_dir:
		ensure => directory,
		owner  => 'root',
		group  => 'mailman',
		mode   => '2775',
	}

	$site_pw_hash = sha1($site_pw)
	file { [$site_pw_file, $creator_pw_file]:
		ensure  => present,
		content => "$site_pw_hash\n",
		owner   => 'root',
		group   => 'mailman',
		mode    => '0644',
	}


	# TODO: is there a simpler way to generate a decent password?
	# TODO: avoid generating a password every time?
	$site_list_pw = generate("/bin/sh", "-c", "PATH=/bin:/usr/bin; dd bs=64 count=1 if=/dev/urandom 2> /dev/null | tr -dc 'a-zA-Z0-9' | fold -c16 | head -n1")
	package { 'mailman':
		ensure  => installed,
	} -> concat { 'mm_cfg':
		path    => "${prefix}/Mailman/mm_cfg.py",
		owner   => 'root',
		group   => 'mailman',
		mode    => '0644',
	} -> exec { 'create_site_list':
		command => "newlist --quiet '${mailman_site_list}' '${mailman_site_list}@${default_email_host}' '${site_list_pw}'",
		path    => $bin_dir,
		creates => "${list_data_dir}/${mailman_site_list}/config.pck",
		require => File[$list_data_dir],
	} -> service { 'mailman':
		ensure  => $activate_qrunners,
		enable  => $activate_qrunners,
	}

	# Concat::fragment MUST come after concat. Not totally sure why.
	concat::fragment { 'mm_cfg_top':
		content => template("${module_name}/mm_cfg.py.erb"),
		target  => 'mm_cfg',
		order   => '00',
	}
	
	# MUST leave concat fragments until after "concat" is declared.
	include mailman::options
}
