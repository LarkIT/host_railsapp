require 'spec_helper'

describe 'host_railsapp::rvm_install' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "without any parameters" do
          let(:params) { { :main_ruby_version => 'ruby-2.0.0-p481', :default_rails_version => '4.1.1' } }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rvm_system_ruby('ruby-2.0.0-p481') }
          it { is_expected.to contain_rvm_gem('rails').with(:ruby_version => 'ruby-2.0.0-p481@global', :ensure => '4.1.1')}
        end

        context "all parameters" do
          let(:pre_condition) do
            [
              "class host_railsapp {
                $main_ruby_version = '1.2.3'
                $default_rails_version = '2.3.4'
              }",
              "include host_railsapp"
            ]
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rvm_system_ruby('1.2.3') }
          it { is_expected.to contain_rvm_gem('rails').with(:ruby_version => '1.2.3@global', :ensure => '2.3.4')}
        end
      end # on os
    end
  end
end
