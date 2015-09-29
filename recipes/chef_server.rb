#
# Cookbook Name:: cert_poc
# Recipe:: chef_server
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

chef_server_rpm = Chef::Config[:file_cache_path] + "/chef-server.rpm"

remote_file chef_server_rpm do
  source node['cert_poc']['chef_server']['rpm']
  not_if "rpm -q chef-server-core"
end

rpm_package "chef_server" do
  source chef_server_rpm
  notifies :delete, "remote_file[#{chef_server_rpm}]", :immediately
  not_if "rpm -q chef-server-core"
end

#-------------------------------------------------------#
# we may need a preliminary chef-ctl-reconfigure here?? #
#-------------------------------------------------------#

#--------------------------------------------------------------------------------------------------------------#
# Run the following command to create an administrator:
# $ chef-server-ctl user-create user_name first_name last_name email password --filename FILE_NAME
# An RSA private key is generated automatically. This is the user’s private key and should be saved to a safe
# location. The --filename option will save the RSA private key to a specified path.
# For example:
# $ chef-server-ctl user-create stevedanno Steve Danno steved@chef.io abc123 --filename /path/to/stevedanno.pem
#--------------------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------------------#
# Run the following command to create an organization:
# $ chef-server-ctl org-create short_name "full_organization_name" --association_user user_name --filename ORGANIZATION-validator.pem
# The organization name must begin with a lower-case letter or digit, may only contain lower-case letters, digits,
# hyphens, and underscores, and must be between 1 and 255 characters. For example: 4thcoffee.
# The full organization name must begin with a non-white space character and must be between 1 and 1023 characters.
# For example: "Fourth Coffee, Inc.".
# The --association_user option will associate the user_name with the admins security group on the Chef server.
# An RSA private key is generated automatically. This is the chef-validator key and should be saved to a safe location.
# The --filename option will save the RSA private key to a specified path.
# For example:
# $ chef-server-ctl org-create 4thcoffee "Fourth Coffee, Inc." --association_user stevedanno --filename /path/to/4thcoffee-validator.pem
#--------------------------------------------------------------------------------------------------------------#

execute 'chef-server-ctl install opscode-manage' do
  creates '/etc/yum.repos.d/chef-stable.repo'
end

%w(opscode-manage opscode).each do |dir|
  directory "/etc/#{dir}"
end

template '/etc/opscode-manage/manage.rb' do
  source 'manage.rb.erb'
end

template '/etc/opscode/chef-server.rb' do
  source 'chef-server.rb.erb'
end

execute 'chef-server-ctl reconfigure' do
  creates '/etc/opscode/pivotal.pem'
end

execute 'opscode-manage-ctl reconfigure' do
  creates '/etc/opscode-manage/secrets.rb'
end




# Enable additional features of the Chef server! The packages may be downloaded directly as part of the installation process or they may be first downloaded to a local directory, and then installed.
#
# Use Downloads
#
# The install subcommand downloads packages from https://packagecloud.io/ by default. For systems that are not behind a firewall (and have connectivity to https://packagecloud.io/), these packages can be installed as described below.
#
# FeatureCommand
# Chef Manage
# Use Chef management     console to manage data bags, attributes, run-lists, roles, environments, and cookbooks from a web user interface.
#
# On the Chef server, run:
#
# $ chef-server-ctl install opscode-manage
# then:
#
# $ chef-server-ctl reconfigure
# and then:
#
# $ opscode-manage-ctl reconfigure
