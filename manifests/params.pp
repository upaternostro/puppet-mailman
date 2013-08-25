# == Class: mailman::params
#
# Full description of class mailman here.
#
# === Parameters
#
# [*MTA*]
#   The MTA param names a module in the Mailman/MTA dir which contains the mail
#   server-specific functions to be executed when a list is created or removed.
#
# === Examples
#
#  include mailman::params
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
	$exec_prefix     = $prefix,
	$var_prefix      = '/var/lib/mailman',
) {
	$default_email_host  = $hostname
	$default_url_host    = $hostname
	$default_url_pattern = 'http://%s/mailman/'


	$list_data_dir   = "${var_prefix}/lists"
	$data_dir        = "${var_prefix}/data"
	$spam_dir        = "${var_prefix}/spam"
	$wrapper_dir     = "${exec_prefix}/mail"
	$bin_dir         = "${prefix}/bin"
	$scripts_dir     = "${prefix}/scripts"
	$template_dir    = "${prefix}/templates"
	$messages_dir    = "${prefix}/messages"

	case $::osfamily {
		'RedHat': {
			$log_dir      = '/var/log/mailman'
			$lock_dir     = '/var/lock/mailman'
			$config_dir   = '/etc/mailman'
			$pid_dir      = '/var/run/mailman'
			$queue_dir    = '/var/spool/mailman'
		}
		default: {
			fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
		}
	}

	$pid_file        = "${pid_dir}/master-qrunner.pid"
	$site_pw_file    = "${config_dir}/adm.pw"
	$creator_pw_file = "${config_dir}/creator.pw"
}
