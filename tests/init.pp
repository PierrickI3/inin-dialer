class {'dialer':
  ensure => 'installed',
  product => 'ODS',
  version => '2015_R2',
  ccsservername => 'localhost',
}