    # There is a bug in the RHEL distribution of Mailman that
    # breaks the script called "mmsitepass". This patches it.
    # http://mail.python.org/pipermail/mailman-users/2011-June/071756.html
    file { "/usr/lib/mailman/bin/mmsitepass":
        ensure  => file,
        mode    => "0755",
        owner   => "root",
        group   => "mailman",
        source  => "puppet:///modules/unbc_mailman/mmsitepass",
        require => Package['mailman'],
    }
    file { "/usr/lib/mailman/bin/genaliases":
        ensure  => file,
        mode    => "0755",
        owner   => "root",
        group   => "mailman",
        source  => "puppet:///modules/unbc_mailman/genaliases",
        require => Package['mailman'],
    }

