module Source
    class ObservationOrg
        module Repo
            AUTH_FILE_PATH = '/tmp/observation.org.auth'.freeze

            module_function
            
            def get_cached_auth_data()
                if !File.file?(AUTH_FILE_PATH)
                    return nil
                end

                return JSON.parse(File.read(AUTH_FILE_PATH))
            end

            def cache(auth_data)
                File.write(AUTH_FILE_PATH, auth_data.to_json)
            end
        end
    end
end
