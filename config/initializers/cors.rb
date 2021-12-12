Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
        origins '*'
        resource '*', 
            headers: ['DNT','X-CustomHeader','Keep-Alive','User-Agent','X-Requested-With','If-Modified-Since','Cache-Control','Content-Type'], 
            methods: [:get, :options]
    end
end
