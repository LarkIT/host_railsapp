require 'spec_helper'

describe 'host_railsapp::application' do
  let(:title) { 'foo' }
  let(:pre_condition) do
    [
      "rvm_system_ruby {'ruby-2.0.0-p481': }",
      'class host_railsapp::rvm_install {}',
      "class host_railsapp::nginx::passenger {}",
      "class host_railsapp::nginx::service {}",
      "class host_railsapp {
        $main_ruby_version = 'ruby-2.0.0-p481'
        $webroot_dir = '/web'
        include ::host_railsapp::nginx::passenger
        include ::host_railsapp::nginx::service
        include ::host_railsapp::rvm_install
      }",
      "include host_railsapp"
    ]
  end
  params = {
    :app_dir_selinux_settings => {
      'seluser'  => 'unconfined_u',
      'selrole'  => 'object_r',
      'seltype'  => 'user_home_dir_t',
      'selrange' => 's0',
    },
    :database_config => {},
    :manage_ssh_keys => true,
    :purge_ssh_keys => true,
    :rails_environments => ['development', 'staging', 'production'],
  }
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "with class parameters" do
          let(:params) do
            params
          end
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_user('foo').with(:home => '/web/foo') }
          it { is_expected.to contain_host_railsapp__directory('/web/foo').with(:owner => 'foo', :group => 'foo', :mode => '0700')}
          it { is_expected.to contain_file('/web/foo/.gemrc').with(:owner => 'foo', :group => 'foo')}
          it { is_expected.to contain_rvm__system_user('foo') }
          it { is_expected.to contain_host_railsapp__rails_environment('foo-development') }
          it { is_expected.to contain_host_railsapp__rails_environment('foo-staging') }
          it { is_expected.to contain_host_railsapp__rails_environment('foo-production') }
          it { is_expected.to contain_file('/web/foo/.ssh').with(:owner => 'foo', :group => 'foo') }
          it { is_expected.to contain_host_railsapp__sshkeys('foo') }
          it { is_expected.to contain_file('/web/foo/.ssh/authorized_keys').with(:owner => 'foo', :group => 'foo', :mode => '0600') }
        end

        context "with array rails environment" do
          let(:params) { params.merge({ :rails_environments => ['bar'] }) }
          it { is_expected.to contain_host_railsapp__rails_environment('foo-bar') }
        end

        context "with user_home_dir" do
          let(:params) { params.merge({ :user_home_dir => '/foo' }) }
          it { is_expected.to contain_user('foo').with(:home => '/foo') }
          it { is_expected.to contain_host_railsapp__directory('/foo').with(:owner => 'foo', :group => 'foo', :mode => '0700')}
          it { is_expected.to contain_file('/foo/.gemrc').with(:owner => 'foo', :group => 'foo')}
          it { is_expected.to contain_rvm__system_user('foo') }
          it { is_expected.to contain_host_railsapp__rails_environment('foo-development') }
          it { is_expected.to contain_host_railsapp__rails_environment('foo-staging') }
          it { is_expected.to contain_host_railsapp__rails_environment('foo-production') }
          it { is_expected.to contain_file('/foo/.ssh').with(:owner => 'foo', :group => 'foo') }
          it { is_expected.to contain_host_railsapp__sshkeys('foo') }
          it { is_expected.to contain_file('/foo/.ssh/authorized_keys').with(:owner => 'foo', :group => 'foo', :mode => '0600') }
        end
      end # on os
    end
  end
end
