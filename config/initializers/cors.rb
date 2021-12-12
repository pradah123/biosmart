Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
        origins 'biosmart.life'
        resource '/api/count/*',
            headers: :any,
            methods: :get,
            if: proc { |env| env['HTTP_HOST'] =~ 'biosmart.life' }
        resource '/api/observations',
            headers: :any,
            methods: :get,
            if: proc { |env| env['HTTP_HOST'] =~ 'biosmart.life' }
    end
end
