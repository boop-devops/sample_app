# rubocop:disable RakeEnvironment, Metrics/BlockLength
namespace :puma do
    Rake::Task["puma:restart"].clear_actions
    Rake::Task["puma:start"].clear_actions
    Rake::Task["puma:stop"].clear_actions
  
    before :start, :make_dirs
    before :start, :enable_service
  
    desc "Create Directories for Puma Pids and Socket"
    task :make_dirs do
      on roles(fetch(:puma_role)) do
        execute "mkdir #{shared_path}/tmp/sockets -p"
        execute "mkdir #{shared_path}/tmp/pids -p"
      end
    end
  
    desc "Upload config service Puma"
    task :upload_service do
      on roles(fetch(:puma_role)) do
        upload!("./systemctl/#{fetch(:service_puma_name)}.service", "/tmp/#{fetch(:service_puma_name)}.service")
        sudo :mv, "/tmp/#{fetch(:service_puma_name)}.service", "#{fetch(:system_path)}/#{fetch(:service_puma_name)}.service"
      end
    end
  
    task :enable_service do
      on roles(fetch(:puma_role)) do
        unless test "[ -f #{fetch(:system_path)}/#{fetch(:service_puma_name)}.service ]"
          warn "Not found #{fetch(:service_puma_name)} service."
          invoke "puma:upload_service"
        end
        sudo :systemctl, "enable", fetch(:service_puma_name)
      end
    end
  
    task :disable_service do
      on roles(fetch(:puma_role)) do
        sudo :systemctl, "disable", fetch(:service_puma_name)
      end
    end
  
    task :start do
      on roles(fetch(:puma_role)) do
        if test "[ -f #{fetch(:puma_conf)} ]"
          info "using conf file #{fetch(:puma_conf)}"
        else
          invoke "puma:config"
        end
  
        if test("[ -f #{fetch(:puma_pid)} ]") && test(:kill, "-0 $( cat #{fetch(:puma_pid)} )")
          info "Puma is already running"
        else
          within current_path do
            with rack_env: fetch(:puma_env) do
              sudo :systemctl, "daemon-reload"
              sudo :systemctl, "start", fetch(:service_puma_name)
            end
          end
        end
      end
    end
  
    task :stop do
      on roles(fetch(:puma_role)) do
        if test "[ -f #{fetch(:puma_pid)} ]"
          if test :kill, "-0 $( cat #{fetch(:puma_pid)} )"
            within current_path do
              sudo :systemctl, "daemon-reload"
              sudo :systemctl, "stop", fetch(:service_puma_name)
            end
          else
            warn "process is not running. Force stop"
            execute :rm, fetch(:puma_pid)
            invoke "puma:force_stop"
          end
        else
          # pid file not found, so puma is probably not running or it using another pidfile
          warn "Not found #{fetch(:puma_pid)}. Force stop"
          invoke "puma:force_stop"
        end
      end
    end
  
    task :restart do
      puts "Overwriting puma:restart to ensure that puma is running from systemctl."
      on roles fetch(:puma_role) do |_role|
        if test "[ -f #{fetch(:system_path)}/#{fetch(:service_puma_name)}.service ]"
          sudo :systemctl, "daemon-reload"
        else
          invoke "puma:upload_service"
        end
        sudo :systemctl, "restart", fetch(:service_puma_name)
      end
    end
  
    task :force_stop do
      on roles fetch(:puma_role) do |_role|
        execute "sleep 1 && pkill -KILL -f 'puma'"
      end
    end
  end
  # rubocop:enable RakeEnvironment, Metrics/BlockLength
  