# config valid for current version and patch releases of Capistrano
lock "~> 3.17.0"

# set :repo_url, "https://gitlab.com/earthguardians1/biosmart-api.git"
set :repo_url, "git@gitlab.com:earthguardians1/biosmart-api.git"

set :branch, ->{ fetch(:branch) }

set :rvm_custom_path, '/usr/share/rvm'
set :rvm_map_bins, fetch(:rvm_map_bins, []).push('rails')

# Default value for :linked_files is []
append :linked_files, "config/database.yml", 'config/master.key', '.env', 'config/puma.rb'

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage"

# Default value for local_user is ENV['USER']
set :local_user, "ubuntu"

set :migration_role, :app

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
set :ssh_options, verify_host_key: :always

set :pty, true
set :ssh_options, {
  forward_agent: true,
  auth_methods: ["publickey"],
  keys: [
    '/home/ubuntu/.ssh/keys/biosmart-staging.pem',
    '/home/ubuntu/.ssh/keys/bee-staging.pem'
  ]
}

set :delayed_job_workers, 2

after 'deploy:symlink:release', 'assets:compile'
after 'puma:restart', 'deploy:restart'
