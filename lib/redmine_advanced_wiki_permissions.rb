require 'active_support/concern'

#hooks
require 'redmine_advanced_wiki_permissions/hooks/view_layouts_base_html_head_hook'
# Patches
require 'redmine_advanced_wiki_permissions/patches/upgrade_version_patches'
require 'redmine_advanced_wiki_permissions/patches/application_controller_patch'
require 'redmine_advanced_wiki_permissions/patches/application_helper_patch'
require 'redmine_advanced_wiki_permissions/patches/group_patch'
require 'redmine_advanced_wiki_permissions/patches/mailer_patch'
require 'redmine_advanced_wiki_permissions/patches/principal_patch'
require 'redmine_advanced_wiki_permissions/patches/project_patch'
require 'redmine_advanced_wiki_permissions/patches/projects_helper_patch'
require 'redmine_advanced_wiki_permissions/patches/search_controller_patch'
require 'redmine_advanced_wiki_permissions/patches/user_patch'
require 'redmine_advanced_wiki_permissions/patches/wiki_controller_patch'
require 'redmine_advanced_wiki_permissions/patches/wiki_page_patch'
