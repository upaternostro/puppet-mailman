# == Class: mailman::apache
#
# Full description of class mailman here.
#
# NOTE: Assumes that you are using name-based virtual hosting on your Apache server.
# Creating a binding in port 80 without namevirtualhost will lead to overlaps
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
class mailman::apache {
	$default_url_host   = $mailman::params::default_url_host
	$default_email_host = $mailman::params::default_email_host
	$prefix             = $mailman::params::prefix
	$log_dir            = $mailman::params::log_dir
	$public_archive_dir = '/var/lib/mailman/archives/public'

        $vhost_file         = "/etc/httpd/conf.d/mailman.conf"
        $server_name        = $default_url_host
        $server_admin       = "mailman@${default_email_host}"
        $document_root      = '/var/www/html/mailman'
        $mailman_cgi_dir    = "${prefix}/cgi-bin"
        $mailman_icons_dir  = "${prefix}/icons"
        $custom_log         = "${log_dir}/apache_access_log"
        $error_log          = "${log_dir}/apache_error_log"

	file { $document_root:
		ensure  => directory,
		owner   => 'apache',
		group   => 'apache',
		mode    => '2775',
	}

	file { [ $custom_log, $error_log ]:
		ensure  => present,
		owner   => 'mailman',
		group   => 'mailman',
		mode    => '0664',
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
