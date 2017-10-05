require 'spec_helper'

describe 'host_railsapp::nginx::service' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "host_railsapp::nginx::service with class parameters" do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_service('nginx').with(:ensure => 'running', :enable => true)}
        end
      end # on os
    end
  end
end
