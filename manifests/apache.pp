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

  if $::operatingsystem == 'Fedora' and versioncmp($::operatingsystemrelease, '18') >= 0 {
    fail('Fedora >= 18 includes Apache 2.4 which is unsupported')
  }

  class { '::apache':
    servername    => $server_name,
    serveradmin   => $server_admin,
    default_mods  => false,
    default_vhost => false,
  }

  #include apache::mod::cgi
  #include apache::mod::mime
  #include apache::mod::mime_magic
  #include apache::mod::autoindex
  #include apache::mod::negotiation
  #include apache::mod::dir
  #include apache::mod::alias
  #include apache::mod::setenvif

  apache::vhost { $server_name:
    #port            => '80',
    docroot         => $document_root,
    # TODO: doesn't apache module have these constants?
    docroot_owner   => $http_username,
    docroot_group   => $http_username,
    ssl             => false,
    #access_log_file => $custom_log,
    #error_log_file  => $error_log,
    logroot         => $log_dir,
    ip_based        => true, # dedicate apache to mailman
    custom_fragment => "ScriptAlias /mailman/ ${mailman_cgi_dir}/",
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
        options         => ['ExecCGI'],
        order           => 'Allow,Deny',
        custom_fragment => 'AddDefaultCharset Off'
      }        
    ],
    
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
