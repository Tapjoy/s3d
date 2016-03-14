#!/usr/bin/env ruby

PROJECT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../")

$LOAD_PATH.unshift(PROJECT_ROOT)

require 'rspec'
require 'its'
require 'securerandom'
require 'scripts/shared.rb'

git_tag  = `git describe --abbrev=0 --tags 2>/dev/null`.chomp
git_tag  = git_tag != "" ? git_tag : "v0.0.0"
git_sha1 = `git rev-parse HEAD | head -c 8`

RSpec.describe ConfigFile do

  before(:all) {
    @tmp_file = "/tmp/s3d#{SecureRandom.uuid}"
    tmp_file_content = <<EOM
    {

      "upload": {
        "dir": "build"
      },

      "aws": {
        "account": "my-prod-user",
        "keyfile": ".aws.prodkeys"
      },

      "bucket": {
        "name": "name.of.my.bucket",
        "path": "/project/$git_tag-$git_sha1"
      },

      "cdns": {
        "cloudfront": "https://b33fgotm11k.cloudfront.net",
        "akamai": "https://e9474.b.akamaiedge.net"
      }

    }
EOM
    File.open(@tmp_file, 'w') { |file| file.write(tmp_file_content) }
  }

  after(:all) {
    File.delete(@tmp_file)
  }

  context "using git" do
    subject { ConfigFile.new(@tmp_file) }

    its(:upload_dir) { should == "#{PROJECT_ROOT}/build"}
    its(:aws_account) { should == "my-prod-user"}
    its(:aws_keyfile) { should == ".aws.prodkeys"}
    its(:bucket_name) { should == "name.of.my.bucket"}
    its(:bucket_path) { should == "/project/#{git_tag}-#{git_sha1}"}
    its(:command) { should == "sync"}
    its(:cdns) do
      should == {"cloudfront" => "https://b33fgotm11k.cloudfront.net", "akamai" => "https://e9474.b.akamaiedge.net" }
    end
  end

  context "supplying git_tag and git_sha1" do
    subject { ConfigFile.new(@tmp_file, '7', '12345') }
    its(:bucket_path) { should == "/project/7-12345"}
  end
end

