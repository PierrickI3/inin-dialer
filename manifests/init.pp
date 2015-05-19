# == Class: dialer
#
# Installs and configures Dialer's ODS and CCS products
#
# === Parameters
#
# [ensure]
#   Only 'installed' is supported at this time to install and configure Dialer products
#
# [product]
#   Either ODS (Outbound Dialer Server) or CCS (Central Campaign Server)
#
# [version]
#   Dialer version (i.e. 2015_R2)
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
  $version,
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

  if (!$version)
  {
  	err('dialer version is not defined')
  	fail('dialer version is not defined')
  }

  $mountdriveletter = 'e:'
  $daascache        = 'C:\\daas-cache'
  $dialeriso        = "Dialer_${version}.iso"

  case $ensure
  {
    installed:
    {
      # Mount Dialer ISO
      debug('Mounting Dialer ISO')
      exec {'mount-dialer-iso':
        command => "cmd.exe /c imdisk -a -f \"${daascache}\\${dialeriso}\" -m ${mountdriveletter}",
        path    => $::path,
        cwd     => $::system32,
        creates => "${mountdriveletter}/Installs/ServerComponents/Dialer_${version}.msi",
        timeout => 30,
      }

      # Unmount CIC ISO
      debug('Unmounting Dialer ISO')
      exec {'unmount-dialer-iso':
        command => "cmd.exe /c imdisk -D -m ${mountdriveletter}",
        path    => $::path,
        cwd     => $::system32,
        timeout => 30,
        require => [
                    Exec['mount-dialer-iso'],
                    #Exec['set-windows-culture'],
                  ],
      }

    }
  }

}