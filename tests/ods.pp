class {'dialer':
  ensure        => 'installed',
  product       => 'ODS',
  version       => '2015_R3',
  ccsservername => 'cic-2015r3',
}