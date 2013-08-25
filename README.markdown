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

### Customize default options for new lists

### Frontend on different server

### 

## Limitations
This module has been built on and tested against these Puppet versions:
* 3.2.4

This module has been tested on the following distributions:
* Scientific Linux release 6.4
