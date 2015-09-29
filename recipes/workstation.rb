#
# Cookbook Name:: cert_poc
# Recipe:: workstation
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

chef_user = node['cert_poc']['user']

# update to current kernel mods/distro
execute "yum update -y" do
  not_if "yum check-update"
end

# basic workstation setup
user chef_user do
  comment "Chef User"
  shell "/bin/bash"
  home "/home/#{chef_user}"
  supports :manage_home => true
  password node['cert_poc']['password'].crypt("$6$" + rand(36**8).to_s(36))
end

sudo "chef_user" do
  user chef_user
  nopasswd true
  defaults ['!requiretty']
end

chef_dk 'install' do
  global_shell_init true
end

template "/home/#{chef_user}/.bashrc" do
  source "bashrc.erb"
  owner chef_user
  group chef_user
  mode "0644"
end

# enable password login
service "sshd" do
  action :nothing
end

template "/etc/ssh/sshd_config" do
  source "sshd_config.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[sshd]"
end

# disable selinux & iptables because complexity
case node["platform"]
  when "redhat", "centos", "fedora"
  template "/etc/selinux/config" do
    source "selinux-config.erb"
    owner "root"
    group "root"
    mode "0644"
  end
end

service 'iptables' do
  supports :status => true, :restart => true, :reload => true
  action [:stop, :disable]
end

