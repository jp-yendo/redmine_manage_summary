RedmineApp::Application.routes.draw do
  match 'time_manage_summary/:action', :to => 'time_manage_summary#index', :via => [:get, :post], as: 'managesummary_top_route'
  match 'time_manage_summary/:action/:id', :to => 'time_manage_summary#show', :via => [:get, :post], as: 'managesummary_project_route'
  #match 'manage_summary/index' => 'managesummary#index', :via => [:get, :post], :controller => 'ManageSummaryController', as: "test_route"
end