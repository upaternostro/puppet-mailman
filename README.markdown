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
running a RedHat-based distribution of Linux, such as CentOS or Scientific.

Simplicity across a variety of configurations is the goal for this module.
* Reasonable defaults make it easier to get started.
* Full support for SELinux in "enforcing" mode when using NFS mounts.
* Extra parameter validation protects against invalid configuration.

This module is divided into logical parts that make it easy to separate the
Mailman web frontend from the MTA backend.

Hiera automatic parameter lookup is fully supported thanks to the extensive use
of parameterized classes.

This modules simplifies a commonly requested feature, which is the ability to
change the location of VAR_PREFIX in mm_cfg.py. For more on that discussion see here:
* https://bugs.launchpad.net/mailman/+bug/925502
* https://bugzilla.redhat.com/show_bug.cgi?id=786822

## Quick Start
I just want Mailman to work. What's the minimum I need?

    class { 'mailman':
      enable_service => true,
      site_pw        => 'CHANGEME',
      mta            => 'Postfix',
    }
    include mailman::apache

This assumes that Postfix is already installed, and that you will manually
hack the `main.cf` Postfix configuration file to add appropriate alias_maps.

For web integration, this assumes that a stock installation of Apache is
available, and that you will be using the server hostname in the URL.

## Usage

### Change location of Mailman data files
This module allows you to fully customize where your Mailman data is stored.
However, only a few directories are ususally worth moving.

    class { 'mailman':
      data_dir      => '/srv/mailman/data'
      list_data_dir => '/srv/mailman/lists'
      queue_dir     => '/srv/mailman/spool'
      log_dir       => '/srv/mailman/logs'
    }

This assumes that `/srv/mailman/` already exists as a directory.

### Customize default options for new lists
If you want to customize the behaviour of newly created mailing lists, you
can change the default options for them. This only affects lists created
in the future, not lists that already exist.

    class { 'mailman::options':
      default_send_reminders   => false,
      default_archive_private  => 1,
      default_max_message_size => 500,
    }

### Frontend on different server
If you want to split up your Mailman environment so that the web frontend runs
on one server, and the queues run on a different server, you need to ensure
that the qrunners are only running on one server.

They need to use shared storage, such as NFS.

    node 'mail.contoso.com' {
      class { 'mailman':
        enable_service => true,
        mta            => 'Postfix',
        data_dir       => '/nfs/mailman/data'
        list_data_dir  => '/nfs/mailman/lists'
        queue_dir      => '/nfs/mailman/spool'
        log_dir        => '/nfs/mailman/logs'
      }
    }
    node 'frontend.contoso.com' {
      class { 'mailman':
        enable_service => false,
        data_dir       => '/nfs/mailman/data'
        list_data_dir  => '/nfs/mailman/lists'
        queue_dir      => '/nfs/mailman/spool'
        log_dir        => '/nfs/mailman/logs'
      }
      include mailman::apache
    }

### Configuration using Hiera
(Examples coming soon)

## Limitations
This module has been built on and tested against these Puppet versions:
* 3.2.4

This module has been tested on the following distributions:
* Scientific Linux release 6.4
