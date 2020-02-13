Redmine::Plugin.register :redmine_advanced_wiki_permissions do

  name 'Redmine Advanced Wiki Permissions plugin'
  author 'Anton Tsapov'
  description 'This is plugin add permissions for every wiki page in project'
  version '1.0.0'
  url 'http://nexstep.ua/'

  requires_redmine version_or_higher: '4.1.0'

  project_module :redmine_advanced_wiki_permissions do
    permission :manage_wiki_rights, { :wiki => :permissions }, :require => :member
  end
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
