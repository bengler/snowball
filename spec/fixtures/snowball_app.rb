class SnowballApp < Sinatra::Base
  register Sinatra::Snowball
  snowball do |s|
    s.http_path "/js"
    s.source_path "spec/fixtures/js"
    s.source_path "spec/fixtures/js"
    s.source_path "spec/fixtures/js/other-source"
    s.raw "js/raw-2.js"
    s.raw "js/raw.coffee"
    s.transforms [:jade, :'coffee-script']
    s.extensions [:jade, :'coffee']
  end

  get "/javascript_tag" do
    haml '= javascript_tag("some")'
  end

  get "/javascript_tag_async" do
    haml '= javascript_tag("pastry/tart", async: true)'
  end

  get "/javascript_path" do
    haml "%script{:src => javascript_path('food/steak')}"
  end
end