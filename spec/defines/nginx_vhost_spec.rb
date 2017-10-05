require 'spec_helper'

describe 'host_railsapp::nginx::vhost' do
  let(:title) { 'foo-development' }
  let(:pre_condition) { ["class host_railsapp::nginx::passenger {}", "class host_railsapp::nginx::service {}", "include host_railsapp::nginx::passenger", "include host_railsapp::nginx::service"] }
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "required params only" do
          let(:params) do
            {
              :approot      => '/www/foo',
              :ruby_gemset  => 'ruby-2.0.0-p481@foo-development',
              :rails_env    => 'development',
              :nginx_conf_d => '/opt/nginx/conf/conf.d',
            }
          end
          it { is_expected.to compile.with_all_deps }
          # not verifying parameters in conf file
          it { is_expected.to contain_file('/opt/nginx/conf/conf.d/vhost-10-foo-development.conf') }
          it { is_expected.to contain_file('/var/log/nginx') }
        end

        context "with ssl" do
          let(:params) do
            {
              :approot      => '/www/foo',
              :ruby_gemset  => 'ruby-2.0.0-p481@foo-development',
              :rails_env    => 'development',
              :ssl_dir      => '/opt/nginx/conf/ssl',
              :ssl_cert     => 'mycertcontents',
              :ssl_key      => 'mykeycontents',
              :nginx_conf_d => '/opt/nginx/conf/conf.d',
            }
          end
          it { is_expected.to contain_file('/opt/nginx/conf/conf.d/vhost-10-foo-development.conf') }
          it { is_expected.to contain_file('/opt/nginx/conf/ssl/foo-development.crt') }
          it { is_expected.to contain_file('/opt/nginx/conf/ssl/foo-development.key') }
        end

        context "docroot or approot is required" do
            it { expect { is_expected.to contain_host_railsapp__nginx__vhost('foo-development')}.to raise_error(Puppet::Error, /host_railsapp::foo-development: Either 'docroot' or 'approot' must be specified/) }
        end

        context "ruby_gemset required with passenger_enabled" do
          let(:params) { { :approot => 'a', :rails_env => 'b' } }
          it { expect { is_expected.to contain_host_railsapp__nginx__vhost('foo-development')}.to raise_error(Puppet::Error, /host_railsapp::foo-development: 'ruby_gemset' is required when passenger_enabled = 'on'/) }
        end

        context "rails_env required with passenger_enabled" do
          let(:params) { { :approot => 'a', :ruby_gemset => 'b' } }
          it { expect { is_expected.to contain_host_railsapp__nginx__vhost('foo-development')}.to raise_error(Puppet::Error, /host_railsapp::foo-development: 'rails_env' is required when passenger_enabled = 'on'/) }
        end

        context "with redirect" do
          let(:params) do
            {
                :passenger_enabled => false,
                :nginx_conf_d      => '/opt/nginx/conf/conf.d',
                :server_name       => 'example.com',
                :vhost_options     => {
                  'return' => '301 $scheme://www.example.com$request_uri',
                },
            }
          end
          filename = '/opt/nginx/conf/conf.d/vhost-10-foo-development.conf'
          it { is_expected.to contain_file(filename).with(:content => /return\s+301 \$scheme:\/\/www.example.com\$request_uri/) }
          it { is_expected.not_to contain_file(filename).with(:content => /passenger_enabled/) }
        end
      end # on os
    end
  end
end
