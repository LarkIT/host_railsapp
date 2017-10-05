require 'spec_helper'

describe 'host_railsapp::nginx::passenger' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "host_railsapp::nginx::passenger with class parameters" do
          # Comes from the main class, dependencies should be reworked
          let(:pre_condition) { ["rvm_system_ruby { '1.2.3': ensure => present }"] }
          let(:params) do
            {
              :ruby_version      => '1.2.3',
              :passenger_version => '2.3.4',
              :rvm_prefix        => '/opt/rvm',
              :nginx_prefix      => '/opt/nginx',
              :ssl_dir           => '/opt/nginx/conf/conf.d',
              :nginx_conf_d      => '/opt/nginx/ssl',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_user('nginx') }
          it { is_expected.to contain_group('nginx') }
          it { is_expected.to contain_class('rvm::passenger::gem').with(:ruby_version => '1.2.3', :version => '2.3.4')}
          it { is_expected.to contain_class('rvm::passenger::dependencies') }
          it do
            is_expected.to contain_exec('passenger-install-nginx-module').with(
              :command => '/opt/rvm/bin/rvm 1.2.3 exec passenger-install-nginx-module --auto --auto-download --prefix=/opt/nginx',
              :unless  => '[ -x /opt/nginx/sbin/nginx ] && /opt/nginx/sbin/nginx -V 2>&1 | grep -q 1.2.3/gems/passenger-2.3.4',
            )
          end
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_root \/opt\/rvm\/gems\/1\.2\.3\/gems\/passenger-2\.3\.4/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_ruby \/opt\/rvm\/wrappers\/1.2.3\/ruby/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_max_pool_size 6/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_pool_idle_time 0/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_max_instances_per_app 0/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_min_instances 1/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_spawn_method smart-lv2/) }
          it { is_expected.to contain_file('/opt/nginx/conf/conf.d').with(:ensure => 'directory') }
          it { is_expected.to contain_file('/opt/nginx/ssl').with(:ensure => 'directory') }
          it { is_expected.to contain_file('/etc/init.d/nginx').with(:content => /nginx=\${NGINX-\/opt\/nginx\/sbin\/nginx/) }
          it { is_expected.to contain_file('/etc/init.d/nginx').with(:content => /CONFFILE-\/opt\/nginx\/conf\/nginx\.conf/) }
        end

        context "changeing passenger options" do
          let(:pre_condition) { ["rvm_system_ruby { '1.2.3': ensure => present }"] }
          let(:params) do
            {
              :nginx_prefix       => '/opt/nginx',
              :ssl_dir            => '/opt/nginx/conf/conf.d',
              :nginx_conf_d       => '/opt/nginx/ssl',
              :mininstances       => '4',
              :maxpoolsize        => '3',
              :poolidletime       => '2',
              :maxinstancesperapp => '1',
              :spawnmethod        => 'foo',
            }
          end

          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_max_pool_size 3/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_pool_idle_time 2/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_max_instances_per_app 1/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_min_instances 4/) }
          it { is_expected.to contain_file('/opt/nginx/conf/nginx.conf').with(:content => /passenger_spawn_method foo/) }
        end
      end # on os
    end
  end
end
