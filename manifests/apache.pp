# == Class: mailman::apache
#
# Full description of class mailman here.
#
# NOTE: Assumes that you are using name-based virtual hosting on your Apache server.
# Suggest integration with logrotate too?
#
# TODO: maybe drop a blank favicon in there if nothing is there yet, just to stem the tide of 404 errors
#
# === Parameters
#
# [*MTA*]
#   The MTA param names a module in the Mailman/MTA dir which contains the mail
#   server-specific functions to be executed when a list is created or removed.
#
# === Examples
#
#  include mailman::apache
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::apache (
	$vhost_file = '/etc/httpd/conf.d/mailman.conf',
	$mailman_cgi_dir = '/usr/lib/mailman/cgi-bin',
	$mailman_icons_dir = '/usr/lib/mailman/icons',

	$server_name   = 'localhost',
	$server_admin  = 'postmaster@lists.nicwaller.com',
	$document_root = '/var/www/html/mailman',
	$http_log_dir  = '/var/log/mailman/www',

	$public_archives_dir = '/var/lib/mailman/archives/public',
) {
	$custom_log    = "${http_log_dir}/access_log"
	$error_log     = "${http_log_dir}/error_log"

	file { $document_root:
		ensure  => directory,
		owner   => 'apache',
		group   => 'apache',
		mode    => '0555',
	}

	file { $http_log_dir:
		ensure  => directory,
		owner   => 'apache',
		group   => 'mailman',
		mode    => '755',
		seltype => 'httpd_log_t',
	}

	file { $vhost_file:
		ensure  => present,
		content => template("${module_name}/mailman_vhost.conf.erb"),
		owner   => 'root',
		group   => 'mailman',
		mode    => '0644',
	}

	# TODO: would be nice to make apache reload after changing all this. but intermodule deps are sticky. any way to do that other than exec?
}
