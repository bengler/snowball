class SnowballApp < Sinatra::Base
  register Sinatra::Snowball
  snowball do
    http_path "/js"
    source_path "spec/fixtures/js"
    source_path "spec/fixtures/js/food"
    raw "*/food/steak.js"
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