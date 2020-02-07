class DelegatePermissionsController < ApplicationController
  include WikiPermissionsHelper
  unloadable

  before_filter :deny_access_for_wiki_page

  def index
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
        end
      end
    end
  end

  def new
    if request.post? &&
       params[:member] &&
       params[:member][:user_ids]
      user_id = params[:member][:user_ids].is_a?(Array) ? params[:member][:user_ids].first : params[:member][:user_ids]
      @dp = DelegatePermission.new
      @dp.user_id = user_id
    end
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
        end
      end
    end
  end

  def create
    if request.post? &&
       params[:member] &&
       params[:member][:permitted]
      @dp = DelegatePermission.new
      @dp.user_id = params[:user_id]
      @dp.project = @project
      @dp.permitted = params[:member][:permitted].map(&:to_i)
      @dp.banned = []
      @dp.save
    end
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
        end
      end
    end
  end

  def edit
    if request.post? &&
       params[:id]
      @dp = DelegatePermission.find(params[:id])
    end
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
        end
      end
    end
  end

  def update
    if request.post? &&
       params[:id] &&
       params[:member] &&
       (params[:member][:permitted] || params[:member][:banned])
      @dp = DelegatePermission.find(params[:id])
      @dp.permitted |= params[:member][:permitted] ? params[:member][:permitted].map(&:to_i) : []
      @dp.banned |= params[:member][:banned] ? params[:member][:banned].map(&:to_i) : []
      @dp.save
      principal_ids = params[:member][:permitted].to_a.map(&:to_i) + params[:member][:banned].to_a.map(&:to_i)
    end
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
            principal_ids.each {|id| page.visual_effect(:highlight, "member-#{id}")}
        end
      end
    end
  end

  def destroy
    if request.post? &&
       params[:id]
      dp = DelegatePermission.find(params[:id])
      user_id = dp.user_id
      dp.destroy
      @deleted_dp_id = params[:id]
    end
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'ajax-modal', :partial => 'delegate_permissions/destroy_following', :locals => { :user_id => user_id }
            page << "showModal('ajax-modal', '400px');"
        end
      end
    end
  end

  def destroy_following_wpps
    wpps = WikiPagePermission.find(:all, :conditions => { :delegate_permission_id => params[:id] } )
    wpps.each { |wpp| wpp.destroy } if wpps.any?
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
        end
      end
    end
  end

  def update_following_wpps
    wpps = WikiPagePermission.find(:all, :conditions => { :delegate_permission_id => params[:id] } )
    wpps.each { |wpp| wpp.update_attribute(:delegate_permission_id, nil) } if wpps.any?
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
        end
      end
    end
  end

  def change_user_edit
    @dp = DelegatePermission.find(params[:id])
    @users = User.active.find(:all, :order => "firstname")
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace_html 'ajax-modal', :partial => 'delegate_permissions/change_user'
          page << "showModal('ajax-modal', '400px');"
        end
      end
    end
  end

  def change_user_update
    @dp = DelegatePermission.find(params[:id])
    if User.find_by_login(params[:author_id]) && @dp.update_attribute(:user_id, User.find_by_login(params[:author_id]).id)
      respond_to do |format|
        format.js do
          render(:update) do |page|
              page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
          end
        end
      end
    else
      flash[:error] = 'error updating. may be wrong author?'
      redirect_to :controller => "delegate_permissions", :action => "change_user_edit", :project_id => @project.id, :id => @dp.id
    end
  end

  def autocomplete_for_user_change
    if params[:user]
      @users = User.active.all(:conditions => ["LOWER(login) LIKE :user OR LOWER(firstname) LIKE :user OR LOWER(lastname) LIKE :user", {:user => params[:user]+"%" }],
                               :limit => 10,
                               :order => 'login ASC')
    end
    @users ||=[]
    render :layout => false
  end

  def destroy_permitted
    if request.post? &&
       params[:id] &&
       params[:principal_id]
      @dp = DelegatePermission.find(params[:id])
      @dp.permitted -= [params[:principal_id].to_i]
      @dp.save
    end
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
        end
      end
    end
  end

  def destroy_banned
    if request.post? &&
       params[:id] &&
       params[:principal_id]
      @dp = DelegatePermission.find(params[:id])
      @dp.banned -= [params[:principal_id].to_i]
      @dp.save
    end
    respond_to do |format|
      format.js do
        render(:update) do |page|
            page.replace_html 'tab-content-manage_wiki_rights', :partial => 'projects/settings/manage_wiki_rights'
        end
      end
    end
  end

  def autocomplete_for_new_dp
    if request.post?
      delete_ids = @project.delegate_permissions.map(&:user_id)
      @principals = Principal.active.like(params[:q]).find(:all, :limit => 100)
      @principals.delete_if {|principal| delete_ids.include?(principal.id)}
      render :layout => false
    end
  end

  def autocomplete_for_permitted
    @principals = Principal.active.like(params[:q]).find(:all, :limit => 100)
    if params[:id]
      @dp = DelegatePermission.find(params[:id])
      delete_ids = @dp.permitted
      @principals.delete_if {|principal| delete_ids.include?(principal.id)}
    end
    render :layout => false
  end

  def autocomplete_for_banned
    @principals = User.active.like(params[:q])
    @dp = DelegatePermission.find(params[:id])
    @principals &= @dp.users_from_permitted_groups
    delete_ids = @dp.banned
    @principals.delete_if {|principal| delete_ids.include?(principal.id)}
    render :layout => false
  end

  private
  def deny_access_for_wiki_page
    if params[:project_id]
      @project = Project.find(params[:project_id])
      deny_access unless User.current.wiki_manager?(@project)
    else
      deny_access
    end
  end
end

