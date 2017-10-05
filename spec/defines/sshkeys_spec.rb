require 'spec_helper'

describe 'host_railsapp::sshkeys' do
  let(:title) { 'railsuser' }

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "without any parameters" do
          let(:params) { { :keys => { 'bob' => {'key' => 'mykey'} } } }
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_ssh_authorized_key('railsuser-bob').with(:user => 'railsuser', :key => 'mykey') }
        end

        context "failures" do
          context "user" do
            let(:params) { { :user => {}, :keys => { 'bob' => {'key' => 'mykey'} } } }
            it { expect { is_expected.to contain_class('host_railsapp') }.to raise_error(Puppet::Error, /{} is not a string/) }
          end

          context "keys" do
            let(:params) { { :keys => 'wrong' } }
            it { expect { is_expected.to contain_class('host_railsapp') }.to raise_error(Puppet::Error, /"wrong" is not a Hash/) }
          end
        end #failures
      end # on os
    end
  end
end
