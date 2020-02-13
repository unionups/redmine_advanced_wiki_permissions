class DelegatePermissionsController < ApplicationController
  include WikiPermissionsHelper
  unloadable
  before_action :deny_access_for_wiki_page
  
  def index
    respond_to :js
  end

  def new
    if params[:member] &&
      params[:member][:user_ids]
      user_id = params[:member][:user_ids].is_a?(Array) ? params[:member][:user_ids].first : params[:member][:user_ids]
      @dp = DelegatePermission.new
      @dp.user_id = user_id
    end
    respond_to :js
  end

  def create
    if  params[:member] &&
        params[:member][:permitted]
      @dp = DelegatePermission.new
      @dp.user_id = params[:user_id]
      @dp.project = @project
      @dp.permitted = params[:member][:permitted].map(&:to_i)
      @dp.banned = []
      @dp.save
    end
    respond_to :js
  end

  def edit
    @dp = DelegatePermission.find(params[:id])
    respond_to :js
  end

  def update
    if params[:id] &&
       params[:member] &&
       (params[:member][:permitted] || params[:member][:banned])
      @dp = DelegatePermission.find(params[:id])
      @dp.permitted |= params[:member][:permitted] ? params[:member][:permitted].map(&:to_i) : []
      @dp.banned |= params[:member][:banned] ? params[:member][:banned].map(&:to_i) : []
      @dp.save
      @principal_ids = params[:member][:permitted].to_a.map(&:to_i) + params[:member][:banned].to_a.map(&:to_i)
    end
    respond_to :js
  end

  def destroy
    dp = DelegatePermission.find(params[:id])
    @user_id = dp.user_id
    dp.destroy
    @deleted_dp_id = params[:id]
    respond_to :js
  end

  def destroy_following_wpps
    @wpps = WikiPagePermission.find_by(delegate_permission_id: params[:id])
    @wpps.each { |wpp| wpp.destroy } if @wpps.try(:any?)
    respond_to :js
  end


  def update_following_wpps
    @wpps = WikiPagePermission.find_by(delegate_permission_id: params[:id])
    @wpps.each { |wpp| wpp.update_attribute(:delegate_permission_id, nil) } if @wpps.try(:any?)
    respond_to :js
  end

  def change_user_edit
    @dp = DelegatePermission.find(params[:id]) if params[:id]
    @users = User.active.order(:firstname)
    respond_to :js
  end

  def change_user_update
    @dp = DelegatePermission.find(params[:id]) if params[:id]
    unless User.find_by_login(params[:author_id]) && @dp.update_attribute(:user_id, User.find_by_login(params[:author_id]).id)
      flash[:error] = 'error updating. may be wrong author?'
      redirect_to :action => "change_user_edit", :project_id => @project.id, :id => @dp.id
    end
    respond_to :js
  end

  def autocomplete_for_user_change
    if params[:user]
      @users = User.active.where("LOWER(login) LIKE :user OR LOWER(firstname) LIKE :user OR LOWER(lastname) LIKE :user", user: params[:user]+"%").order('login ASC').first(10)
    end
    @users ||=[]
    render :layout => false
  end

  def destroy_permitted
    if params[:principal_id]
      @dp = DelegatePermission.find(params[:id])
      @dp.permitted -= [params[:principal_id].to_i]
      @dp.save
    end
    respond_to :js
  end

  def destroy_banned
    if params[:principal_id]
      @dp = DelegatePermission.find(params[:id])
      @dp.banned -= [params[:principal_id].to_i]
      @dp.save
    end
    respond_to :js
  end

  def autocomplete_for_new_dp
      delete_ids = @project.delegate_permissions.map(&:user_id)
      @principals = Principal.active.like(params[:q]).first(100)
      @principals.to_a.delete_if {|principal| delete_ids.include?(principal.id)}
      render :layout => false
  end

  def autocomplete_for_permitted
    @principals = Principal.active.like(params[:q]).first(100)
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

