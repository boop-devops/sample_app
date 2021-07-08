lock "~> 3.16.0"

append :linked_files, "config/database.yml", "config/master.key"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "public/packs", "public/uploads", "node_modules"

set :application, "sample_app"
set :repo_url, "git@github.com:boop-devops/sample_app.git"
set :branch, :master
set :stage, :production
set :rails_env, :production
set :assets_roles, :app
set :migration_role, :db
set :conditionally_migrate, true
set :rvm_type, :user                # Defaults to: :auto
set :rvm_ruby_version, "2.6.6"      # Defaults to: 'default'
set :puma_threads,    [4, 16]
set :puma_workers,    0
set :puma_role,       :app
set :deploy_via,      :remote_cache
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :puma_preload_app, false
set :puma_worker_timeout, 30
set :puma_init_active_record, true # Change to true if using ActiveRecord
set :git_environmental_variables, {}
set :service_puma_name, "puma"
set :system_path, "/etc/systemd/system"

namespace :deploy do
  desc "Make sure local git is in sync with remote."

  desc "Initial Deploy"
  task :initial do
    on roles(:app) do
      before "deploy:restart", "puma:start"
      invoke "deploy"
    end
  end

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke "puma:phased-restart"
    end
  end

  after  :finishing,          :cleanup
end
