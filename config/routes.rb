RedmineApp::Application.routes.draw do
  match 'time_summary/:action', :to => 'time_summary#index', :via => [:get, :post], as: 'managesummary_top_route'
  match 'time_summary/:action/:id', :to => 'time_summary#show', :via => [:get, :post], as: 'managesummary_project_route'
end