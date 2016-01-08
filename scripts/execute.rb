#!/usr/bin/env ruby

dir = File.expand_path(File.dirname(__FILE__))
require "#{dir}/shared.rb"

cf = ConfigFile.new(ARGV[0], ARGV[1], ARGV[2])

output = `aws s3 sync #{cf.upload_dir} s3://#{cf.bucket_name}#{cf.bucket_path} --acl public-read #{cf.bucket_options}`

puts output

