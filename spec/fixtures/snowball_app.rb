class SnowballApp < Sinatra::Base
  register Sinatra::Snowball
  snowball do
    set_serve_path "/assets"
    add_load_path "spec/fixtures/js"
  end
end