# == Class: dialer
#
# Installs and configures Dialer's ODS and CCS products.
# If CCS is selected, will install the latest version available.
# If ODS is selected, will install the same version than the installed CIC.
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
# [ccsservername]
#   Name or IP address of the CCS
#
# === Examples
#
#  To install ODS:
# 
#  class { 'dialer':
#    ensure        => 'installed',
#    product       => 'ODS',
#    ccsservername => 'ccsserver',
#  }
#
#  To install CCS:
#
#  class { 'dialer':
#    ensure        => 'installed',
#    product       => 'CCS',
#    ccsservername => '',
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
  $ensure = 'installed',
  $product,
  $ccsservername,
  $dbtemplate = 'dialer/createdatabase.sql.erb',
  $connectiontemplate = 'dialer/connection.udl.erb',
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

  $cache_dir = hiera('core::cache_dir', 'c:/users/vagrant/appdata/local/temp') # If I use c:/windows/temp then a circular dependency occurs when used with SQL
  if (!defined(File[$cache_dir]))
  {
    file {$cache_dir:
      ensure   => directory,
      provider => windows,
    }
  }

  $mountdriveletter = 'f:'
  $daascache        = 'C:/daas-cache'
  if ($product == 'CCS')
  {
    $dialeriso = latest_version($daascache, 'Dialer_[0-9]*_R?.iso')
    $versiontouse = $dialeriso[7,7]
  }
  else
  {
    $versiontouse = "${::cic_installed_major_version}_R${::cic_installed_release}"
    $dialeriso    = "Dialer_${versiontouse}.iso"
  }

  $sa_password      = 'D0gf00d'
  $database         = 'DialerDB'

  case $ensure
  {
    installed:
    {

      # Mount Dialer ISO. No need to unmount it since we reboot 
      # once the installs are done.
      debug('Mounting Dialer ISO')
      exec {'mount-dialer-iso':
        command => "cmd.exe /c imdisk -a -f \"${daascache}/${dialeriso}\" -m ${mountdriveletter}",
        path    => $::path,
        cwd     => $::system32,
        creates => "${mountdriveletter}/Installs/ServerComponents/Dialer_${versiontouse}.msi",
        timeout => 30,
      }

      # Install ODS or CCS based on the $product parameter
      case $product
      {
        'ODS':
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
            source          => "${mountdriveletter}\\Installs\\ServerComponents\\ODS_${versiontouse}.msi",
            install_options => [
              '/l*v',
              "c:\\windows\\logs\\ods_${versiontouse}.log",
              '/qn',
              '/norestart',
              {'STARTEDBYEXEORIUPDATE' => '1'},
              {'REBOOT'                => 'ReallySuppress'},
              {'CCSSERVERNAME'         => $ccsservername },
            ],
            require         => [
              Exec['mount-dialer-iso'],
            ],
            notify          => Reboot['after-install'],
            provider        => windows,
          }

          # Notifier Registry Fix
          debug('Creating Powershell script to fix Notifier registry value if needed...')
          file {"${cache_dir}\\FixNotifierRegistryValue_ods.ps1":
            ensure  => 'file',
            owner   => 'Vagrant',
            group   => 'Administrators',
            content => "
              \$NotifierRegPath = \"HKLM:\\SOFTWARE\\Wow6432Node\\Interactive Intelligence\\EIC\\Notifier\"
              \$NotifierKey = \"NotifierServer\"

              \$CurrentNotifierValue = (Get-ItemProperty -Path \$NotifierRegPath -Name \$NotifierKey).NotifierServer
              if (\$CurrentNotifierValue -ne \$CurrentComputerName)
              {
                  Write-Host \"Current Notifier registry value is not set properly. Fixing...\"
                  Set-ItemProperty -Path \$NotifierRegPath -Name \$NotifierKey -Value \$env:COMPUTERNAME
              }
            ",
            before  => Exec['notifier-fix'],
          }

          debug('Fixing Notifier registry value if needed...')
          exec {'notifier-fix':
            command => "${cache_dir}\\FixNotifierRegistryValue_ods.ps1",
            provider => powershell,
            timeout  => 3600,
            require  => Package['dialer-ods-install'],
          }

          notify {'installed':
            require => Package['dialer-ods-install'],
          }
        }

        'CCS':
        {
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
            source          => "${mountdriveletter}\\Installs\\Off-ServerComponents\\CCS_${versiontouse}.msi",
            install_options => [
              '/l*v',
              'c:\\windows\\logs\\ccs.log',
              '/qn',
              '/norestart',
              {'STARTEDBYEXEORIUPDATE'   => '1'},
              {'REBOOT'                  => 'ReallySuppress'},
              {'INTERACTIVEINTELLIGENCE' => 'C:\\I3\\IC'},
              {'PROMPTEDUSER'            => 'vagrant'},
              {'PROMPTEDPASSWORD'        => 'vagrant'},
              {'PROMPTEDDOMAIN'          => $::hostname},
              {'TRACING_LOGPATH'         => 'C:\\I3\\IC\\Logs'},
            ],
            require         => [
              Exec['mount-dialer-iso'],
              Package['sql2008r2.nativeclient'],
              Package['sql2008r2.cmdline'],
              Class['sqlserver'],
            ],
            provider        => windows,
            # TODO Create a custom fact to check if Interaction Center service is running
          }

          # Notifier Registry Fix
          debug('Creating Powershell script to fix Notifier registry value if needed...')
          file {"${cache_dir}\\FixNotifierRegistryValue_ccs.ps1":
            ensure  => 'file',
            owner   => 'Vagrant',
            group   => 'Administrators',
            content => "
              \$NotifierRegPath = \"HKLM:\\SOFTWARE\\Wow6432Node\\Interactive Intelligence\\EIC\\Notifier\"
              \$NotifierKey = \"NotifierServer\"

              \$CurrentNotifierValue = (Get-ItemProperty -Path \$NotifierRegPath -Name \$NotifierKey).NotifierServer
              if (\$CurrentNotifierValue -ne \$CurrentComputerName)
              {
                  Write-Host \"Current Notifier registry value is not set properly. Fixing...\"
                  Set-ItemProperty -Path \$NotifierRegPath -Name \$NotifierKey -Value \$env:COMPUTERNAME
              }
            ",
            before  => Exec['notifier-fix'],
          }

          debug('Fixing Notifier registry value if needed...')
          exec {'notifier-fix':
            command => "${cache_dir}\\FixNotifierRegistryValue_ccs.ps1",
            provider => powershell,
            timeout  => 3600,
            require  => Package['dialer-ccs-install'],
          }

          # File containing the script to create the Dialer database
          file {'c:/tmp/createdatabase.sql':
            ensure  => present,
            content => template($dbtemplate),
          }

          # Create the Dialer database
          $sqlcmd = '"C:\\Program Files\\Microsoft SQL Server\\Client SDK\\ODBC\\110\\Tools\\Binn\\sqlcmd.exe"'
          exec {'create-sql-database':
            command => "${sqlcmd} -U sa -P \"${sa_password}\" -i C:\\tmp\\createdatabase.sql",
            cwd     => $::system32,
            path    => $::path,
            require => [
              File['c:/tmp/createdatabase.sql'],
              Package['dialer-ccs-install'],
            ],
          }

          # Create the UDL file
          file {'C:/I3/IC/Server/UDL/connection.udl':
            ensure  => present,
            content => template($connectiontemplate),
            require => [
              Exec['create-sql-database'],
              Package['dialer-ccs-install'],
            ],
            notify  => Reboot['after-install'],
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
        message => 'Install of CCS or ODS is finished. Rebooting.',
      }

    }
    default:
    {
      debug("Unknown command ${ensure}")
    }
  }

}