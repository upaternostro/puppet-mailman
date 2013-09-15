# == Class: mailman::options
#
# This is an optional class that can be used to customize the defaults used when
# creating new mailing lists. However, note that these settings have no effect
# on mailing lists that have already been created.
#
# The default values for the parameters in this class match the default values of
# a standard Mailman installation. If this class isn't declared, then the options
# won't be included in mm_cfg.py.
#
# === Parameters
#
# All of the parameters in this class have a 1:1 correspondence with Mailman
# variables defined in Default.py. A complete reference about list settings
# is available on the Mailman website:
# http://www.gnu.org/software/mailman/mailman-admin/node8.html
#
# === Examples
#
# class { 'mailman::options':
#   default_send_reminders   => false,
#   default_archive_private  => 1,
#   default_max_message_size => 500,
# }
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::options (
  $default_send_reminders               = true,
  $default_archive_private              = 0,
  $default_max_message_size             = 40, # in KB
  $default_msg_footer                   = '""',
  $default_subscribe_policy             = 1,
  $default_private_roster               = 1,
  $default_generic_nonmember_action     = 1,
  $default_forward_auto_discards        = true,
  $default_require_explicit_destination = true,
  $default_max_num_recipients           = 10,
) inherits mailman::params {
  validate_bool($default_send_reminders)
  validate_re($default_archive_private, [0,1])
  validate_re($default_max_message_size, '[0-9]*')
  validate_re($default_msg_footer, ['^""".*$', '".*"'])
  validate_re($default_subscribe_policy, [0,1,2,3])
  validate_re($default_private_roster, [0,1,2])
  validate_re($default_generic_nonmember_action, [0,1,2,3])
  validate_bool($default_forward_auto_discards)
  validate_bool($default_require_explicit_destination)
  validate_re($default_max_num_recipients, '[0-9]*')

  concat::fragment { 'mm_cfg_options':
    content => template("${module_name}/mm_cfg_options.py.erb"),
    target  => 'mm_cfg',
    order   => '50',
  }
}
