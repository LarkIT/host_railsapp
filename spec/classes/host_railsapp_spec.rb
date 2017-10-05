require 'spec_helper'

describe 'host_railsapp' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "without any parameters" do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('host_railsapp') }
          it { is_expected.to contain_class('host_railsapp::params') }

          it { is_expected.to contain_class('host_railsapp::nginx::passenger') }
          it { is_expected.to contain_host_railsapp__directory('/web').with(:mode => '0711') }
        end

        context "all parameters" do
          let(:params) do
            {
              :webroot_dir => '/opt/web',
              :webroot_dir_permissions => '0444',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('host_railsapp') }
          it { is_expected.to contain_class('host_railsapp::params') }

          it { is_expected.to contain_class('host_railsapp::nginx::passenger') }
          it { is_expected.to contain_host_railsapp__directory('/opt/web').with(:mode => '0444') }
        end

        context "applications hash" do
          let(:params) { { :applications => {'foo' => {}, 'foo2' => {} } } }
          it { is_expected.to contain_host_railsapp__application('foo') }
          it { is_expected.to contain_host_railsapp__application('foo2') }
        end
        
        context "applications name only" do
          let(:params) { { :applications => 'foo' } }
          it { is_expected.to contain_host_railsapp__application('foo') }
        end
      end # on os
    end
  end
end
