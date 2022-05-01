# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

server "portal-staging.biosmart.life", user: "ubuntu", roles: %w{app}
# server "example.com", user: "deploy", roles: %w{app web}, other_property: :other_value
# server "db.example.com", user: "deploy", roles: %w{db}



# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}

set :stage, :staging
set :application, "biosmart-staging"
set :deploy_to, "/home/ubuntu/biosmart-staging"

set :rvm_ruby_version, '3.0.2'

set :bundle_without, [:development, :production]

set :rails_env, 'test'
set :branch, :main
set :default_env, { rails_env: "test" }

set :delayed_job_pools, {
  'observations_test_queue_observations_fetch' => 1,
  'observations_test_queue_observations_create,observations_test_queue_fetch_observation_org_username' => 1
}
