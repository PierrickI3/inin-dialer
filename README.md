# inin-dialer

[![Build Status](https://travis-ci.org/PierrickI3/inin-dialer.svg?branch=master)](https://travis-ci.org/PierrickI3/inin-dialer)

Puppet module to install and configure ININ's ODS & CCS

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with dialer](#setup)
    * [What dialer affects](#what-dialer-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with dialer](#beginning-with-dialer)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Installs Dialer CCS and/or ODS. See http://www.inin.com/solutions/pages/predictive-dialer-software.aspx for more details.
Requires Windows 2012R2 and a copy of the Dialer 201xRx iso file.

## Module Description

Installs and configures a Central Campaign Server (CCS) and or an Outbound Dialer Server (ODS) 
to use with a CIC server from Interactive Intelligence. Reboots once the install is complete.

## Setup

### What dialer affects

* Installs SQL 2008 R2 Native Client
* Installs SQL Server 2012 Express & creates a database
* Installs CCS or ODS
* Creates a UDL file called C:\tmp\connection.udl

### Setup Requirements

* Dialer ISO file should be in a shared folder located in c:\daas-cache
* For ODS, CIC should already be installed and configured
* For CCS, check the requirements on http://testlab.inin.com/ProductsPage.aspx?ProductType=20 (Dialer section)
* Only tested in Windows 2012R2

## Usage

To install a Central Campaign Server (CCS):

```puppet
class {'dialer':
  ensure        => 'installed',
  product       => 'CCS',
  version       => '2015_R2',
  ccsservername => '',
}
```

To install an Outbound Dialing Server (ODS):

```puppet
class {'dialer':
  ensure        => 'installed',
  product       => 'ODS',
  version       => '2015_R2',
  ccsservername => 'ccsserver',
}
```

## Limitations

* Oracle not supported yet