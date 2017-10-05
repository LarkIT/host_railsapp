require 'spec_helper'

describe 'host_railsapp::rails_environment' do
  let(:title) { 'foo-development' }
  let(:pre_condition) do
    [
      'class host_railsapp::rvm_install {}',
      'class host_railsapp::nginx::passenger {}',
      'class host_railsapp::nginx::service {}',
      'include host_railsapp::rvm_install',
      'include host_railsapp::nginx::passenger',
      'include host_railsapp::nginx::service'
    ]
  end
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context " with foo-development app" do
          let(:params) do
            {
              :application_dir => '/web/foo',
              :ruby_version    => 'ruby-2.0.0-p481',
              :secrets         => {'supersecret' => 'reallysecret' },
              :database_config => { 'a' => 'b' },
            }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rvm_gemset('ruby-2.0.0-p481@foo-development') }
          it { is_expected.to contain_host_railsapp__directory('/web/foo/development') }
          it { is_expected.to contain_file('/web/foo/development/.ruby-version').with(:content => 'ruby-2.0.0-p481') }
          it { is_expected.to contain_file('/web/foo/development/.ruby-gemset').with(:content => 'foo-development') }
          it { is_expected.to contain_host_railsapp__directory('/web/foo/development/shared') }
          it { is_expected.to contain_host_railsapp__directory('/web/foo/development/shared/config') }
          it { is_expected.to contain_host_railsapp__directory('/web/foo/development/shared/log') }
          it { is_expected.to contain_file('/web/foo/development/shared/config/database.yml').with(:mode => '0440') }
          it { is_expected.to contain_file('/web/foo/development/shared/config/secrets.yml').with(:mode => '0440') }
          it { is_expected.to contain_host_railsapp__nginx__vhost('foo-development') }
        end
      end # on os
    end
  end
end
