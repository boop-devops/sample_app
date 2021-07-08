set :user, :deploy
server "192.168.62.128", user: fetch(:user), roles: %w[app db]

set :ssh_options,
    keys: ["~/.ssh/id_rsa"],
    forward_agent: true,
    user: fetch(:user)
