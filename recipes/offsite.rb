# Author:: Paul Mooring <paul@opscode.com>
# Cookbook Name:: opscode-backup
# Recipe:: offsite
#
# Copyright 2013, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

secrets = data_bag_item('secrets', node.chef_environment)

# The backup-rotate script needs ruby, but I don't want to fight with potential
# source installations
package "ruby" do
  not_if "which ruby"
end

cookbook_file '/usr/local/bin/backup-rotate' do
  source 'backup-rotate'
  owner 'root'
  group 'root'
  mode '0755'
end

package 'rsync'

user 'rsync' do
  comment 'Rsync User'
  home    '/backup'
  shell   '/bin/bash'
  system  true
end

directory '/backup' do
  owner 'rsync'
  group 'rsync'
  mode '0755'
end

directory '/backup/.ssh' do
  owner 'rsync'
  group 'rsync'
  mode '0700'
end

file '/backup/.ssh/id_rsa' do
  content secrets['rsync-backups-user.priv']
  owner 'rsync'
  group 'rsync'
  mode '0600'
end

backup_targets = search(:node, 'tags:backupclient').collect do |node|
  node['opscode_backup']['targets']
end.flatten

backup_targets.each do |backup|
  directory "/backup/#{backup}" do
    owner 'rsync'
    group 'rsync'
    mode '0755'
  end
end

template '/etc/cron.d/backup-rotate-cron' do
  source 'offsite-rotate-cron.erb'
  owner 'root'
  group 'root'
  mode '0600'
end
