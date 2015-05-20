require 'puppetlabs_spec_helper/module_spec_helper'
require 'spec_helper'

describe 'dialer' do

  let(:facts) {{ :operatingsystem => 'Windows' }}
  let(:params) {{ :product => 'ODS', :ensure => 'installed', :version => '2015R2', :ccsservername => 'testccs' }}

  # -----------
  # Basic tests
  # -----------

  context 'with defaults for all parameters' do
    it { should contain_class('dialer') }
  end

  context 'contains class' do
  	it { is_expected.to contain_class('dialer')}
  end

  context 'Should only support windows' do
    let(:facts) { { :operatingsystem => 'Not Windows'} }
    
    it do
      expect { 
      	should contain_class('dialer') 
      }.to raise_error(Puppet::Error, /Unsupported OS/)
    end
  end

  # ---------------
  # Parameter tests
  # ---------------
  context 'should fail if product parameter is empty' do
  	let(:params) {{ :product => '', :ensure => 'installed', :version => '2015R2', :ccsservername => 'testccs' }}
  	it do
  	  expect {
  	    should contain_class('dialer') 
  	  }.to raise_error(Puppet::Error, /product must be either ODS or CCS/)
  	end
  end

  context 'should fail if ensure parameter is not set to installed' do
  	let(:params) {{ :product => 'ODS', :ensure => '', :version => '2015R2', :ccsservername => 'testccs' }}
  	it do
  	  expect {
  	    should contain_class('dialer') 
  	  }.to raise_error(Puppet::Error, /only installed is supported for the ensure parameter at this time/)
  	end
  end

  context 'should fail if version parameter is not set' do
  	let(:params) {{ :product => 'ODS', :ensure => '', :ccsservername => 'testccs' }}
  	it do
  	  expect {
  	    should contain_class('dialer') 
  	  }.to raise_error(Puppet::Error, /Must pass version to Class\[Dialer\]/)
  	end
  end

  context 'should fail if ccsservername parameter is not set' do
  	let(:params) {{ :product => 'ODS', :ensure => 'installed', :version => '2015_R2' }}
  	it do
  	  expect {
  	    should contain_class('dialer') 
  	  }.to raise_error(Puppet::Error, /Must pass ccsservername to Class\[Dialer\]/)
  	end
  end

  # --------------
  # Mounting tests
  # --------------
  context 'should mount a drive' do
    it { should contain_exec('mount-dialer-iso')}
  end

  # -------------------------
  # SQL 2008 R2 Native Client
  # -------------------------
  context 'should install sql 2008 r2 native client' do
    it { should contain_package('sql2008r2.nativeclient')}
  end

  # ---
  # ODS
  # ---
  context 'should have an ODS package' do
  	it { should contain_package('dialer-ods-install') }
  end

  context 'should not have an ODS package when CCS is requested' do
  	let(:params) {{ :product => 'CCS', :ensure => 'installed', :version => '2015R2', :ccsservername => '' }}
  	it { should_not contain_package('dialer-ods-install') }
  end

  # ---
  # CCS
  # ---
  context 'should have a CCS package' do
  	let(:params) {{ :product => 'CCS', :ensure => 'installed', :version => '2015R2', :ccsservername => '' }}
  	it { should contain_package('dialer-ccs-install') }
  end

  context 'should not have a CCS package when ODS is requested' do
  	let(:params) {{ :product => 'ODS', :ensure => 'installed', :version => '2015R2', :ccsservername => 'testccs' }}
  	it { should_not contain_package('dialer-ccs-install') }
  end

  # ----
  # .Net
  # ----
  context 'should install .net 3.5' do
  	let(:params) {{ :product => 'ODS', :ensure => 'installed', :version => '2015R2', :ccsservername => 'testccs' }}
  	it { should contain_exec('dotnet-35') }
  end

end