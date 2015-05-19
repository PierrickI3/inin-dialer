# dialer

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
to use with a CIC server from Interactive Intelligence.

## Setup

### What dialer affects

* A list of files, packages, services, or operations that the module will alter,
  impact, or execute on the system it's installed on.
* This is a great place to stick any warnings.
* Can be in list or paragraph form.

### Setup Requirements **OPTIONAL**

* Dialer ISO file should be in a shared folder located in c:\daas-cache
* For ODS, CIC should already be installed and configured
* For CCS, check the requirements on http://testlab.inin.com/ProductsPage.aspx?ProductType=20 (Dialer section)

### Beginning with dialer

The very basic steps needed for a user to get the module up and running.

If your most recent release breaks compatibility or requires particular steps
for upgrading, you may wish to include an additional section here: Upgrading
(For an example, see http://forge.puppetlabs.com/puppetlabs/firewall).

## Usage

Put the classes, types, and resources for customizing, configuring, and doing
the fancy stuff with your module here.

## Reference

Here, list the classes, types, providers, facts, etc contained in your module.
This section should include all of the under-the-hood workings of your module so
people know what the module is touching on their system but don't need to mess
with things. (We are working on automating this section!)

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.

## Release Notes/Contributors/Etc **Optional**

If you aren't using changelog, put your release notes here (though you should
consider using changelog). You may also add any additional sections you feel are
necessary or important to include here. Please use the `## ` header.
