# == Class: mailman::etclinks
#
# A standard Mailman installation has only two parts.
# - Static bits  (represented by PREFIX variable)
# - Dynamic bits (represented by VAR_PREFIX)
# These are typically in /usr/ and /var/ respectively.
#
# However, the Red Hat package maintainer wanted Mailman to fit the FHS more
# closely, so the Red Hat packages have changed the locations of some files
# since Mailman version 2.1.5.
#
# In order to offer the best cross-platform support and ease of use, this
# module ignores the use of /etc/ on Red Hat and puts the files back into
# standard directories. But as a compromise, we can create some symlinks.
#
# === Examples
#
#  include mailman::etclinks
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::etclinks {
  $etc_dir = '/etc/mailman'

  file { $etc_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'mailman',
    mode    => '2775',
    seltype => 'mailman_data_t',
    require => Package['mailman'],
  }
  file { "${etc_dir}/mm_cfg.py":
    ensure  => link,
    target  => "${mailman::prefix}/Mailman/mm_cfg.py",
    require => File[$etc_dir],
  }
  file { "${etc_dir}/adm.pw":
    ensure  => link,
    target  => $mailman::site_pw_file,
    require => File[$etc_dir],
  }
  file { "${etc_dir}/creator.pw":
    ensure  => link,
    target  => $mailman::creator_pw_file,
    require => File[$etc_dir],
  }
  file { "${etc_dir}/aliases":
    ensure  => link,
    target  => "${mailman::data_dir}/aliases",
    require => File[$etc_dir],
  }
  file { "${etc_dir}/aliases.db":
    ensure  => link,
    target  => "${mailman::data_dir}/aliases.db",
    require => File[$etc_dir],
  }
  file { "${etc_dir}/virtual-mailman":
    ensure  => link,
    target  => "${mailman::data_dir}/virtual-mailman",
    require => File[$etc_dir],
  }
}
