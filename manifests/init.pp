# == Class: dialer
#
# Installs and configures Dialer's ODS and CCS products
#
# === Parameters
#
# [product]
#   Either ODS (Outbound Dialer Server) or CCS (Central Campaign Server)
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'dialer':
#    product => 'ODS',
#  }
#
# === Authors
#
# Pierrick Lozach <pierrick.lozach@inin.com>
#
# === Copyright
#
# Copyright 2015 Interactive Intelligence, Inc.
#
include stdlib

class dialer (
  $ensure,
  $product,
)
{

  if ($::operatingsystem != 'Windows')
  {
    err('This module works on Windows only!')
    fail('Unsupported OS')
  }

  if !($product in ['ODS', 'CCS'])
  {
  	err('missing product')
  	fail('product must be either ODS or CCS')
  }

  if !($ensure in ['installed'])
  {
  	err('only installed is supported for ensure parameter at this time')
  	fail('only installed is supported for the ensure parameter at this time')
  }

}