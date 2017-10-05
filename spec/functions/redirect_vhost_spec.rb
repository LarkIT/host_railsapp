require 'spec_helper'

describe "the hash_to_repo_file function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it "should exist" do
    expect(Puppet::Parser::Functions.function("redirect_vhost")).to eq("function_redirect_vhost")
  end

  it "should raise a ParseError if there is less than 1 arguments" do
    expect { scope.function_redirect_vhost([]) }.to( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if something other than a hash is used" do
    expect { scope.function_redirect_vhost(['a','b']) }.to( raise_error(Puppet::ParseError))
  end

  it "should return vhost parameters for redirects (simple format)" do
    redirects = { 'example.com' => 'http://www.example.com', 'example.net' => 'http://www.example.net' }
    result = scope.function_redirect_vhost([redirects])
    expect(result).to(eq({"example.com"=>{"passenger_enabled"=>false, "server_name"=>"example.net", "vhost_options"=>{"return"=>"301 http://www.example.net$request_uri"}}, "example.net"=>{"passenger_enabled"=>false, "server_name"=>"example.net", "vhost_options"=>{"return"=>"301 http://www.example.net$request_uri"}}}))
  end

  it "should return vhost parameters for redirects (davanced format)" do
    redirects = { 'example.net' => {'destination' => 'http://www.example.net', 'ssl_key' => 'asdf', 'ssl_cert' => 'jkl'} }
    result = scope.function_redirect_vhost([redirects])
    expect(result).to(eq({"example.net"=>{"passenger_enabled"=>false, "vhost_options"=>{"return"=>"301 http://www.example.net$request_uri"}, "ssl_key"=>"asdf", "ssl_cert"=>"jkl"}}))
  end
end
