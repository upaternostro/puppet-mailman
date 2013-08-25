# == Class: mailman::options
#
# Full description of class mailman here.
#
# === Parameters
#
# [*virtual_host_overview*]
#   We want the web interface to display lists even when teh URL does not
#   match, which makes it easier to test web interfaces on several servers
#
# === Examples
#
#  include mailman::options
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
  $default_archive_private              = '0',
  $default_max_message_size             = '40', # in KB
  $default_msg_footer                   = '""',
  $default_subscribe_policy             = '1',
  $default_private_roster               = '1',
  $default_generic_nonmember_action     = '1',
  $default_forward_auto_discards        = true,
  $default_require_explicit_destination = true,
  $default_max_num_recipients           = '10',
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
