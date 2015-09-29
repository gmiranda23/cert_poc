#
# Cookbook Name:: cert_poc
# Recipe:: docker
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

group "docker" do
  members ['chef']
  append true
end

%w(xz libcgroup device-mapper-libs).each do |dependency|
  package dependency
end

docker_engine_rpm = Chef::Config[:file_cache_path] + "/docker-engine.rpm"

remote_file docker_engine_rpm do
  source node['cert_poc']['docker']['rpm']
  not_if "rpm -q docker-engine"
end

rpm_package "docker-engine" do
  source docker_engine_rpm
  notifies :delete, "remote_file[#{docker_engine_rpm}]", :immediately
  not_if "rpm -q docker-engine"
end

service "docker" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

execute 'docker pull centos:6' do
  action :run
  not_if "docker images | grep centos"
end

gem_package "kitchen-docker" do
  gem_binary "/opt/chefdk/embedded/bin/gem"
  options "--no-user-install"
  notifies :restart, "service[docker]"
end
