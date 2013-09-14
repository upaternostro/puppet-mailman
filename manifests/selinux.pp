# == Class: mailman::selinux
#
# Installs TE files that allow Mailman to use NFS mounts with SELinux enabled.
# Depends on spiette/selinux module from Puppet Forge.
#
# === Examples
#
#  include mailman::selinux
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::selinux {
  selinux::module { 'mailman_allow_nfs':
    source => "puppet:///modules/${module_name}/selinux/",
    ignore => ['.svn'],
  }

  exec { 'setsebool -P httpd_use_nfs true':
    path   => '/bin:/usr/sbin',
    unless => 'getsebool httpd_use_nfs | grep on',
  }
}
