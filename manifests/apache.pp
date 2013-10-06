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
  $custom_log_name    = 'apache_access_log'
  $error_log_name     = 'apache_error_log'
  $custom_log         = "${log_dir}/${custom_log_name}"
  $error_log          = "${log_dir}/${error_log_name}"
  $favicon            = "${document_root}/favicon.ico"
  $httpd_service      = 'httpd'
  $mm_username        = $mailman::params::mm_username
  $mm_groupname       = $mailman::params::mm_groupname
  $http_username      = $mailman::params::http_username

  if versioncmp($::apacheversion, '2.4.0') >= 0 {
    fail('Apache 2.4 is not supported by this Puppet module.')
  }

  class { '::apache':
    servername    => $server_name,
    serveradmin   => $server_admin,
    default_mods  => true,
    default_vhost => false,
    logroot => '/var/log/httpd',
  }
  apache::listen { '80': }

  include apache::mod::alias

  apache::vhost { $server_name:
    docroot         => $document_root,
    # TODO: doesn't apache module have these constants?
    docroot_owner   => $http_username,
    docroot_group   => $http_username,
    ssl             => false,
    access_log_file => $custom_log_name,
    error_log_file  => $error_log_name,
    logroot         => $log_dir,
    ip_based        => true, # dedicate apache to mailman
    custom_fragment => [
      "ScriptAlias /mailman ${mailman_cgi_dir}/\n",
      "RedirectMatch ^/mailman[/]*$ http://${server_name}/mailman/listinfo\n",
      "RedirectMatch ^/?$ http://${server_name}/mailman/listinfo\n",
    ],
    aliases         => [ { alias => '/pipermail', path => $public_archive_dir } ],
    directories     => [
      {
        path            => $mailman_cgi_dir,
        allow_override  => ['None'],
        options         => ['ExecCGI'],
        order           => 'Allow,Deny',
        allow           => 'from all'
      },
      {
        path            => $public_archive_dir,
        allow_override  => ['None'],
        options         => ['Indexes', 'MultiViews', 'FollowSymLinks'],
        order           => 'Allow,Deny',
        custom_fragment => 'AddDefaultCharset Off'
      }        
    ],
    
  }

  file { [ $custom_log, $error_log ]:
    ensure  => present,
    owner   => $http_username,
    group   => $http_groupname,
    mode    => '0664',
    seltype => 'httpd_log_t',
  }

  # Mailman does include a favicon in the HTML META section, but some silly
  # browsers still look for favicon.ico. Create a blank one to reduce 404's.
  exec { 'ensure_favicon':
    command => "touch ${favicon}",
    path    => '/bin',
    creates => $favicon,
    require => File[$document_root],
  }
}
