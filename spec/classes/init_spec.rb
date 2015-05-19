require 'puppetlabs_spec_helper/module_spec_helper'
require 'spec_helper'
describe 'dialer' do

  context 'with defaults for all parameters' do
    it { should contain_class('dialer') }
  end

  context 'contains class' do
  	it { is_expected.to contain_class('dialer')}
  end
end
