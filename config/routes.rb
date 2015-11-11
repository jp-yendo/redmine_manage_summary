match 'projects/time_summary/:action', :controller => 'time_summary', :via => [:get, :post], as: 'manage_time_summary_top_route'
match 'projects/:id/time_summary/:action', :controller => 'time_summary', :via => [:get, :post], as: 'manage_time_summary_project_route'

match 'projects/progress_summary/:action', :controller => 'progress_summary', :via => [:get, :post], as: 'manage_progress_summary_top_route'
match 'projects/:id/progress_summary/:action', :controller => 'progress_summary', :via => [:get, :post], as: 'manage_progress_summary_project_route'
