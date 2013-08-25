# == Class: mailman
#
# Full description of class mailman here.
#
# Designed to work with Mailman >= 2.1.5, mostly because of where files are located.
#
# TODO: maybe allow creator/adm passwords as class parameters?
#
# === Parameters
# Try to keep defaults similar to Mailman defaults. Exceptions will be clearly noted.
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
	$activate_qrunners = false,

	$default_email_host = 'localhost.localdomain',
	$default_url_host = 'localhost.localdomain',
	$default_url_pattern = 'http://%s/mailman/',

	$language = 'en',
	$mailman_site_list = 'mailman',
	$mta = 'Manual',

        $default_send_reminders = true,
        $default_archive_private = '0',
        $default_max_message_size = '40', # in KB
        $default_msg_footer = '""',
        $default_subscribe_policy = '1',
        $default_private_roster = '1',
        $default_generic_nonmember_action = '1',
        $default_forward_auto_discards = true,
        $default_require_explicit_destination = true,
        $default_max_num_recipients = '10',

	$virtual_host_overview = true,

	$smtp_max_rcpts = '500',

	$prefix = '/usr/lib/mailman',
	$log_dir = '/var/log/mailman',
	$lock_dir = '/var/lock/mailman',
	$pid_dir = '/var/run/mailman',
	$var_prefix = '/var/lib/mailman',
	$queue_dir = '/var/spool/mailman',
) {
	$langs = ['ar','ca','cs','da','de','en','es','et','eu','fi','fr','gl','he',
		'hr','hu','ia','it','ja','ko','lt','nl','no','pl','pt','pt_BR','ro',
		'ru','sk','sl','sr','sv','tr','uk','vi','zh_CN','zh_TW']
	validate_bool($activate_qrunners)
	validate_re($language, $langs)
	validate_re($mailman_site_list, '[-+_.=a-z0-9]*')
	validate_re($mta, ['Manual', 'Postfix'])
	validate_bool($default_send_reminders)
	validate_re($default_archive_private, [0,1])
	validate_re($default_max_message_size, '[0-9]*')
	validate_re($default_msg_footer, ['^""".*$', '".*"'])
	validate_re($default_subscribe_policy, [0,1,2,3])
	validate_re($default_private_roster, [0,1,2])
	validate_re($default_generic_nonmember_action, [0,1,2,3])
	validate_bool($default_forward_auto_discards)
	validate_bool($default_require_explicit_destination)
	validate_re($default_max_num_recipients, '[0-9]*')
	validate_bool($virtual_host_overview)
	validate_re($smtp_max_rcpts, '[0-9]*')

	include mailman::apache

	$exec_prefix = $prefix
	$config_dir = '/etc/mailman'
	$spam_dir = "${var_prefix}/spam"
	$wrapper_dir = "${exec_prefix}/mail"
	$bin_dir = "${prefix}/bin"
	$scripts_dir = "${prefix}/scripts"
	$template_dir = "${prefix}/templates"
	$messages_dir = "${prefix}/messages"

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

	$list_data_dir = "${var_prefix}/lists"

	# Mailman does not automatically create the list data dir
	file { $list_data_dir:
		ensure => directory,
		owner  => 'root',
		group  => 'mailman',
		mode   => '2775',
	}

	# TODO: How can I make it simple to override these variables? If I include them
	# in the paramater list, the default value can't depend on other parameters.
	$pid_file = "${pid_dir}/master-qrunner.pid"
	$data_dir = "${var_prefix}/data"

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

	# TODO: is there a simpler way to generate a decent password?
	# TODO: avoid generating a password every time?
	$site_list_pw = generate("/bin/sh", "-c", "PATH=/bin:/usr/bin; dd bs=64 count=1 if=/dev/urandom 2> /dev/null | tr -dc 'a-zA-Z0-9' | fold -c16 | head -n1")
	package { 'mailman':
		ensure  => installed,
	} -> file { "${prefix}/Mailman/mm_cfg.py":
		content => template("${module_name}/mm_cfg.py.erb"),
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
}
