# == Class: dialer
#
# Installs and configures Dialer's ODS and CCS products
#
# === Parameters
#
# [ensure]
#   Only 'installed' is supported at this time to install 
#   and configure Dialer products
#
# [product]
#   Either ODS (Outbound Dialer Server) or CCS (Central Campaign Server)
#
# [version]
#   Dialer version (i.e. 2015_R2)
#
# [ccsservername]
#   Name or IP address of the CCS
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
include reboot

class dialer (
  $ensure,
  $product,
  $version,
  $ccsservername,
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

  $mountdriveletter = 'f:'
  $daascache        = 'C:/daas-cache'
  $dialeriso        = "Dialer_${version}.iso"
  $sa_password      = 'D0gf00d'
  $database         = 'DialerDB'

  case $ensure
  {
    installed:
    {

      # Reboot if an install is pending
      reboot {'before':
        when    => pending,
        message => 'Installs are pending reboot. Rebooting now.',
      }

      # Mount Dialer ISO. No need to unmount it since we reboot 
      # once the installs are done.
      debug('Mounting Dialer ISO')
      exec {'mount-dialer-iso':
        command => "cmd.exe /c imdisk -a -f \"${daascache}/${dialeriso}\" -m ${mountdriveletter}",
        path    => $::path,
        cwd     => $::system32,
        creates => "${mountdriveletter}/Installs/ServerComponents/Dialer_${version}.msi",
        timeout => 30,
        require => Reboot['before'],
      }

      # Install ODS or CCS based on the $product parameter
      case $product
      {
        ODS:
        {
          if (!$ccsservername)
          {
            err('Name or IP of CCS not specified')
            fail('Name or IP of CCS not specified')
          }

          # Install ODS
          debug('Installing ODS')
          package {'dialer-ods-install':
            ensure          => installed,
            source          => "${mountdriveletter}\\Installs\\ServerComponents\\ODS_${version}.msi",
            install_options => [
              '/l*v',
              "c:\\windows\\logs\\ods_${version}.log",
              '/qn',
              '/norestart',
              {'STARTEDBYEXEORIUPDATE' => '1'},
              {'REBOOT'                => 'ReallySuppress'},
              {'CCSSERVERNAME'         => $ccsservername },
            ],
            require         => [
              Exec['mount-dialer-iso'],
              Exec['dotnet-35'],
              Reboot['before'],
              Package['sql2008r2.nativeclient'],
            ],
            notify          => Reboot['after-install'],
          }

          notify {'installed':
            require => Package['dialer-ods-install'],
          }
        }

        CCS:
        {

          # Install .Net 3.5
          exec {'dotnet-35':
            command  => 'Install-WindowsFeature -name NET-Framework-Core',
            provider => powershell,
            path     => $::path,
            cwd      => $::system32,
            timeout  => 600,
          }

          # Install SQL 2008 R2 Native Client (required for DialerTranServer)
          package {'sql2008r2.nativeclient':
            ensure   => installed,
            provider => chocolatey,
          }

          # Install SQL 2008 R2 Command Line (required to import or export data 
          # from a contact list)
          package {'sql2008r2.cmdline':
            ensure   => installed,
            provider => chocolatey,
            require  => [
              Package['sql2008r2.nativeclient'],
            ],
          }

          # Install SQL Server
          class {'sqlserver':
            ensure          => installed,
            edition         => 'Express',
            features        => ['SQL', 'Tools'],
            sa_password     => $sa_password,
            source          => 'C:\\daas-cache',
            source_user     => '',
            source_password => '',
          }

          # Install CCS
          debug('Installing CCS')
          package {'dialer-ccs-install':
            ensure          => installed,
            source          => "${mountdriveletter}\\Installs\\Off-ServerComponents\\CCS_${version}.msi",
            install_options => [
              '/l*v',
              "c:\\windows\\logs\\ccs_${version}.log",
              '/qn',
              '/norestart',
              {'STARTEDBYEXEORIUPDATE' => '1'},
              {'REBOOT'                => 'ReallySuppress'},
              {'PROMPTEDUSER'          => 'vagrant'},
              {'PROMPTEDPASSWORD'      => 'vagrant'},
              {'PROMPTEDDOMAIN'        => $::hostname},
              {'TRACING_LOGPATH'       => 'C:\\I3\\IC\\Logs'},
            ],
            require         => [
              Reboot['before'],
              Exec['mount-dialer-iso'],
              Exec['dotnet-35'],
              Package['sql2008r2.nativeclient'],
              Package['sql2008r2.cmdline'],
              Class['sqlserver'],
            ],
            notify          => Reboot['after-install'],
          }

          # File containing the script to create the Dialer database
          file {'c:/tmp/createdatabase.sql':
            ensure  => present,
            content => template('dialer/createdatabase.sql.erb'),
          }

          # Create the Dialer database
          exec {'create-sql-database':
            command => "sqlcmd -U sa -P ${sa_password} -d ${database} -i C:\\tmp\\createdatabase.sql",
            cwd     => ::system32,
            path    => ::path,
            require => [
              File['c:/tmp/createdatabase.sql'],
              Package['dialer-ccs-install'],
            ],
          }

          # Create the UDL file
          file {'c:/tmp/dialerdatabase.udl':
            ensure  => present,
            name    => 'connection.udl',
            content => '[oledb]',
            require => [
              Exec['create-sql-database'],
              Package['dialer-ccs-install'],
            ],
          }

          notify {'installed':
            require => [
              Package['dialer-ccs-install'],
              Exec['create-sql-database'],
              File['c:/tmp/dialerdatabase.udl'],
            ],
          }
        }
        default:
        {
          debug("Unknow product ${product}")
        }
      }

      # Reboot when finished. Drive will not be mounted again 
      # so no need to unmount it.
      reboot {'after-install':
        apply   => finished,
        message => 'Install of CCS or ODS is finished. Rebooting',
      }

    }
    default:
    {
      debug("Unknown command ${ensure}")
    }
  }

}