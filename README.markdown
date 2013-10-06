# puppet-mailman

#### Table of Contents
1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Quick Start](#quick-start)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Limitations](#limitations)

## Overview
The Mailman module installs and configures Mailman, the GNU mailing list manager.

## Module Description
The Mailman module is used to setup the Mailman mailing list manager on servers
running either RedHat or Debian-based distributions of Linux. 

Customizing this module to work with your environment is quick and easy. This
module includes simple helper classes to configure Apache and Postfix, but you
can skip either of them if you need a more customized environment.

If your server will be dedicated to running only Mailman, you can use the
Apache helper class to get started quickly. Or if you want to use Apache
for hosting other sites on the same server, you can skip the helper class so
that it won't interfere.

If you want to share Mailman data between two or more servers, this module
provides parameters that make it easy to customize directory paths. And the
optional SELinux module configures SELinux policy so that Mailman is permitted
to read and write files mounted with NFS, even in Enforcing mode.

By providing parameterized classes, full support for Hiera parameter binding
in Puppet >= 3.0 is included. This module can be fully configured from Hiera.

## Quick Start
I just want a dedicated Mailman server. First, install dependencies.

    $ sudo puppet module install puppetlabs/apache
    $ sudo puppet module install thias/postfix

Then declare the Mailman classes in one of your node statements.

    class { 'mailman':
      enable_service => true,
      site_pw        => 'CHANGEME',
      mta            => 'Postfix',
      smtp_hostname  => 'mail.contoso.com',
      http_hostname  => 'mail.contoso.com',
    }
    include mailman::apache
    include mailman::postfix

*CAUTION!* Only use the Apache and Postfix helper classes if your server will
only be hosting Mailman and nothing else. If you want to use Apache or Postfix
for other purposes on the same server, they need to be configured separately.
These helper classes will remove any non-Mailman configuration.

## Usage

### Change location of Mailman data files
Customizing the Mailman directories is easy. For example, if you had already
mounted `/srv/mailman` over NFS, this is how to relocate the directories.

    class { 'mailman':
      list_data_dir => '/srv/mailman/lists',
      log_dir       => '/srv/mailman/logs',
      data_dir      => '/srv/mailman/data',
      queue_dir     => '/srv/mailman/spool',
      archive_dir   => '/srv/mailman/archives',
    }

CAUTION: If you change Mailman's directories after lists have been created, you
will need to manually move the list data to the new directories yourself.

### Web frontend on separate server
If you want to put the web frontend on a separate server, you can put Mailman
data on an NFS share. You *MUST* ensure that Mailman's qrunners are only active
on one server at a time to avoid data corruption. Use the `enable_service`
parameter to specify which server has the qrunners.

    node 'mail.contoso.com' {
      class { 'mailman':
        enable_service => true,
        mta            => 'Postfix',

        list_data_dir  => '/srv/mailman/lists',
        log_dir        => '/srv/mailman/logs',
        data_dir       => '/srv/mailman/data',
        queue_dir      => '/srv/mailman/spool',
        archive_dir    => '/srv/mailman/archives',
      }
      include mailman::postfix
    }
    node 'frontend.contoso.com' {
      class { 'mailman':
        enable_service => false,

        list_data_dir  => '/srv/mailman/lists',
        log_dir        => '/srv/mailman/logs',
        data_dir       => '/srv/mailman/data',
        queue_dir      => '/srv/mailman/spool',
        archive_dir    => '/srv/mailman/archives',
      }
      include mailman::apache
    }

### Custom options
To customize additional options that aren't already included in this module,
use the `option_hash` parameter to define your custom options.

    class { 'mailman':
      option_hash   => { 'DEFAULT_MAX_NUM_RECIPIENTS' => 20 },
    }

### Configuration using Hiera
    ---
    mailman::enable_service: true
    mailman::site_pw: 'CHANGEME'
    mailman::language: 'en'
    mailman::mta: 'Postfix'
    mailman::smtp_hostname: 'localhost.localdomain'
    mailman::smtp_max_rcpts: '50'

Note that all values in Hiera must be quoted, even integer numbers. This is
due to the use of validate_re() which expects all input as strings.

## Limitations
This module is only intended to configure Mailman 2.1.x, the mainstream stable
branch. This is the version currently included in most Linux distributions.

Only single-domain configurations are supported at this time.

The helper class for Apache uses the PuppetLabs apache module, which only
works with Apache 2.2. It is possible to make Mailman work with Apache 2.4
but you need to configure Apache some other way.

This module has been built on and tested against these Puppet versions:
* 3.3.0
* 3.2.4
* 3.1.1

Supported distributions:
* Scientific Linux 6.4
* Ubuntu Server 12.04 LTS

Unsupported distributions:
* Fedora 18/19 (Apache 2.4)
