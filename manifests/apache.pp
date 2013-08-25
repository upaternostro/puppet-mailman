# == Class: mailman::apache
#
# Full description of class mailman here.
#
# NOTE: Assumes that you are using name-based virtual hosting on your Apache server.
# Creating a binding in port 80 without namevirtualhost will lead to overlaps
# Suggest integration with logrotate too?
#
# Also assumes that you aren't managing Apache with a different Puppet class.
#
# Note: httpd is installed as a pre-req for Mailman on RedHat systems, so
# we can assume that httpd service is available.
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
  $prefix             = $mailman::params::prefix
  $log_dir            = $mailman::params::log_dir
  $public_archive_dir = $mailman::public_archive_file_dir

  $vhost_file         = "/etc/httpd/conf.d/mailman.conf"
  $server_name        = $mailman::http_hostname
  $server_admin       = "mailman@${default_email_host}"
  $document_root      = '/var/www/html/mailman'
  $mailman_cgi_dir    = "${prefix}/cgi-bin"
  $mailman_icons_dir  = "${prefix}/icons"
  $custom_log         = "${log_dir}/apache_access_log"
  $error_log          = "${log_dir}/apache_error_log"
  $favicon            = "${document_root}/favicon.ico"
  # TODO make this work on Debian systems too
  $httpd_service      = 'httpd'

  file { $document_root:
    ensure  => directory,
    owner   => 'apache',
    group   => 'apache',
    mode    => '2775',
  }
  # Mailman does include a favicon in the HTML META section, but some silly
  # browsers still look for favicon.ico. Create a blank one to reduce 404's.
  exec { 'ensure_favicon':
    command => "touch ${favicon}",
    path    => '/bin',
    creates => $favicon,
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
    notify  => Service[$httpd_service],
  }

  service { $httpd_service:
    ensure    => running,
    enable    => true,
  }
}
