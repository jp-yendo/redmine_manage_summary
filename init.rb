require 'redmine'

Redmine::Plugin.register :redmine_manage_summary do
  name 'Redmine Manage Summary plugin'
  author 'Yuichiro Endo'
  description 'Redmine Manage Summary plugin'
  version '0.0.1'
  url 'https://github.com/jp-yendo/redmine_manage_summary.git'
  author_url 'https://github.com/jp-yendo'

  project_module :manage_summary do
    permission :view_manage_summary, {:time_manage_summary => [:index]}
    permission :view_manage_project_summary, {:time_manage_summary => [:show]}
  end

  menu :top_menu, :manage_summary,
    {:controller => 'time_manage_summary', :action => 'index'},
    :caption => :menu_label_time_manage_summary,
    :if => Proc.new{User.current.logged?}

  menu :project_menu, :manage_summary,
    {:controller => 'time_manage_summary', :action => 'show'},
    :caption => :menu_label_time_manage_summary #, :after => :new_issue

  settings :partial => 'settings/managesummary_settings',
           :default => {
              'threshold_lowtime'   => 0.1,
              'threshold_normalload'=> 7.6,
              'threshold_overtime'  => 9.6,
              'threshold_hardtime'  => 11.6
           }
end
