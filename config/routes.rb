RedmineApp::Application.routes.draw do
  match 'manage_summary/:action', :to => 'manage_summary#index', :via => [:get, :post], as: 'managesummary_top_route'
  match 'manage_summary/:action/:id', :to => 'manage_summary#show', :via => [:get, :post], as: 'managesummary_project_route'
  #match 'manage_summary/index' => 'managesummary#index', :via => [:get, :post], :controller => 'ManageSummaryController', as: "test_route"
end