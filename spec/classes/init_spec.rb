require 'puppetlabs_spec_helper/module_spec_helper'
require 'spec_helper'

describe 'dialer' do

  let(:facts) {{ :operatingsystem => 'Windows' }}
  let(:params) {{ :product => 'ODS', :ensure => 'installed' }}

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

  context 'should fail if product parameter is empty' do
  	let(:params) {{ :product => '', :ensure => 'installed' }}
  	it do
  	  expect {
  	    should contain_class('dialer') 
  	  }.to raise_error(Puppet::Error, /product must be either ODS or CCS/)
  	end
  end

  context 'should fail if ensure parameter is not set to installed' do
  	let(:params) {{ :product => 'ODS', :ensure => '' }}
  	it do
  	  expect {
  	    should contain_class('dialer') 
  	  }.to raise_error(Puppet::Error, /only installed is supported for the ensure parameter at this time/)
  	end
  end

end