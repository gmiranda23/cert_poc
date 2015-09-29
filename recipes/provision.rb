#
# Cookbook Name:: cert_poc
# Recipe:: provision
#
# Author:: George Miranda (<gmiranda@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'chef/provisioning/aws_driver'

with_driver 'aws::us-east-1' do

  aws_key_pair 'cert_poc_key' do
    allow_overwrite false
    private_key_path "#{ENV['HOME']}/.ssh/cert_poc_key"
  end

  aws_security_group "cert_poc" do
    inbound_rules '0.0.0.0/0' => [22, 3389, 5985, 5986]
  end

  machine 'cert_poc_linux' do
    converge true
    recipe 'cert_poc'
    machine_options({
      :ssh_username => 'root',
      :bootstrap_options => {
        :image_id => 'ami-c2a818aa',
        :instance_type => 'm3.xlarge',
        :key_name => 'cert_poc_key',
        :security_group_ids => ['cert_poc']
      }
    })
  end

  # machine 'cert_poc_windows' do
  #   action :allocate
  #   machine_options({
  #     :is_windows => true,
  #     :bootstrap_options => {
  #       :image_id => 'ami-f70cdd9c',
  #       :instance_type => 'm3.medium',
  #       :key_name => 'cert_poc_key',
  #       :security_group_ids => ['cert_poc']
  #     }
  #   })
  # end
end
