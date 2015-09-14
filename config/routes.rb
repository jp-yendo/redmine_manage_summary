RedmineApp::Application.routes.draw do
  match 'time_summary/:action', :to => 'time_summary#index', :via => [:get, :post], as: 'manage_time_summary_top_route'
  match 'time_summary/:action/:id', :to => 'time_summary#show', :via => [:get, :post], as: 'manage_time_summary_project_route'

  match 'progress_summary/:action', :to => 'progress_summary#index', :via => [:get, :post], as: 'manage_progress_summary_top_route'
  match 'progress_summary/:action/:id', :to => 'progress_summary#show', :via => [:get, :post], as: 'manage_progress_summary_project_route'
end