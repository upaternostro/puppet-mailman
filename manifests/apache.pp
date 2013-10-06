# == Class: mailman::apache
#
# This class provides a bare minimum configuration of Apache for integration
# with Mailman to provide web based moderation and viewing of Archives.
#
# This assumes that you aren't managing Apache in any other Puppet module, and
# that Apache isn't serving any other domains on the same server.
#
# === Examples
#
# include mailman::apache
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
  $log_dir            = $mailman::log_dir
  $public_archive_dir = $mailman::public_archive_file_dir
  $vhost_file         = "/etc/httpd/conf.d/mailman.conf"
  $server_name        = $mailman::http_hostname
  $server_admin       = "mailman@${mailman::smtp_hostname}"
  $document_root      = '/var/www/html/mailman'
  $mailman_cgi_dir    = "${prefix}/cgi-bin"
  $mailman_icons_dir  = "${prefix}/icons"
  $custom_log         = "${log_dir}/apache_access_log"
  $error_log          = "${log_dir}/apache_error_log"
  $favicon            = "${document_root}/favicon.ico"
  $httpd_service      = 'httpd'
  $mm_username        = $mailman::params::mm_username
  $mm_groupname       = $mailman::params::mm_groupname
  $http_username      = $mailman::params::http_username

  package { 'httpd':
    ensure  => installed,
  }

  file { $document_root:
    ensure  => directory,
    owner   => $http_username,
    group   => $http_username,
    mode    => '2775',
    seltype => 'httpd_sys_content_t',
    require => Package['httpd'],
  }
  # Mailman does include a favicon in the HTML META section, but some silly
  # browsers still look for favicon.ico. Create a blank one to reduce 404's.
  exec { 'ensure_favicon':
    command => "touch ${favicon}",
    path    => '/bin',
    creates => $favicon,
    require => File[$document_root],
  }

  file { [ $custom_log, $error_log ]:
    ensure  => present,
    owner   => $mm_username,
    group   => $mm_groupname,
    mode    => '0664',
    seltype => 'httpd_log_t',
  }

  file { $vhost_file:
    ensure  => present,
    content => template("${module_name}/mailman_vhost.conf.erb"),
    owner   => 'root',
    group   => $mm_username,
    mode    => '0644',
    seltype => 'httpd_config_t',
    notify  => Service['httpd'],
  }

  service { $httpd_service:
    ensure    => running,
    enable    => true,
    require   => File[$document_root],
  }
}
