class SnowballApp < Sinatra::Base
  register Sinatra::Snowball
  snowball do
    set_serve_path "/assets"
    add_load_path "spec/fixtures/js"
    add_load_path "spec/fixtures/js/meat"
    set_ignore "*/meat/steak.js"
  end
end