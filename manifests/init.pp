# == Class: mailman
#
# Full description of class mailman here.
#
# TODO: allow uninstallation with "ensure => absnet"
#
# === Parameters
# Try to keep defaults similar to Mailman defaults. Exceptions will be clearly noted.
#
# [*MTA*]
#   The MTA param names a module in the Mailman/MTA dir which contains the mail
#   server-specific functions to be executed when a list is created or removed.
#
# TODO: maybe allow creator/adm passwords as class parameters?
#
# TODO: consider extracting very large sets of parameters into optional classes, then
# building up a single large config file with the concat pattern.
#
# Virtual Host Overview
# we want the web interface to display lists even when teh URL does not
# match, which makes it easier to test web interfaces on several servers
#
# === Examples
#
#  class { mailman:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class mailman (
	$activate_qrunners = false,

	$default_email_host = 'localhost.localdomain',
	$default_url_host = 'localhost.localdomain',
	$default_url_pattern = 'http://%s/mailman/',

	$language = 'en',
	$mailman_site_list = 'mailman',
	$mta = 'manual',

        $default_send_reminders = 'True',
        $default_archive_private = '0',
        $default_max_message_size = '40', # in KB
        $default_msg_footer = '""',
        $default_subscribe_policy = '1',
        $default_private_roster = '1',
        $default_generic_nonmember_action = '1',
        $default_forward_auto_discards = 'True',
        $default_require_explicit_destination = 'True',
        $default_max_num_recipients = '10',

	$virtual_host_overview = 'True',

	$smtp_max_rcpts = '500',

	$log_dir = '/var/log/mailman',
	$lock_dir = '/var/lock/mailman',
	$pid_dir = '/var/run/mailman',
	$var_prefix = '/var/lib/mailman',
	$queue_dir = "/var/spool/mailman",
) {
	# Originally I wanted to use native Python path joins exactly the same
	# as is done in Defaults.py. However, it is useful to have all of the
	# paths fully resolved in the Puppet manifest so they can be used with
	# file resources. Still I try to track Defaults.py as closely as I can.

	# Mailman service will fail if queue_dir is unwritable or doesn't exist.
	file { $queue_dir:
		ensure => directory,
		owner  => 'mailman',
		group  => 'mailman',
		mode   => '2770',
	}

	# TODO: How can I make it simple to override these variables? If I include them
	# in the paramater list, the default value can't depend on other parameters.
	$pid_file = "${pid_dir}/master-qrunner.pid"
	$data_dir = "${var_prefix}/data"
	$list_data_dir = "${var_prefix}/lists4"

	$private_archive_file_dir = "${var_prefix}/archives/private"
	$public_archives_file_dir = "${var_prefix}/archives/public"

        $inqueue_dir     = "${queue_dir}/in"
        $outqueue_dir    = "${queue_dir}/out"
        $cmdqueue_dir    = "${queue_dir}/commands"
        $bouncequeue_dir = "${queue_dir}/bounces"
        $newsqueue_dir   = "${queue_dir}/news"
        $archqueue_dir   = "${queue_dir}/archive"
        $shuntqueue_dir  = "${queue_dir}/shunt"
        $virginqueue_dir = "${queue_dir}/virgin"
        $badqueue_dir    = "${queue_dir}/bad"
        $retryqueue_dir  = "${queue_dir}/retry"
        $maildir_dir     = "${queue_dir}/maildir"


	# TODO activate_qrunners is one of "stopped" or "running", kindof
	# TODO booleans must be input as exactly True or False, and validated
	# TODO carefully validate input to ensure it meets the quoting/non-quoting
	# requirements for python variables

	# TODO: Either localize exec $path or state dependency on Mailman >= 2.1.5

	# TODO: is there a simpler way to generate a decent password?
	# TODO: avoid generating a password every time?
	$site_list_pw = generate("/bin/sh", "-c", "/bin/dd bs=64 count=1 if=/dev/urandom 2> /dev/null | /usr/bin/tr -dc 'a-zA-Z0-9' | /usr/bin/fold -c10 | /usr/bin/head -n1")
	package { 'mailman':
		ensure  => installed,
	} -> file { '/usr/lib/mailman/Mailman/mm_cfg.py':
		content => template("${module_name}/mm_cfg.py.erb"),
		owner   => 'root',
		group   => 'mailman',
		mode    => '0640',
	} -> exec { 'create_site_list':
		command => "newlist --language=${language} --urlhost=${default_url_domain} --emailhost=${default_email_host} --quiet '${mailman_site_list}' '${mailman_site_list}@${default_email_host}' '${site_list_pw}'",
		path    => "/usr/lib/mailman/bin",
		creates => "${list_data_dir}/${mailman_site_list}/config.pck",
	} -> service { 'mailman':
		ensure  => $activate_qrunners,
		enable  => $activate_qrunners,
	}
}
