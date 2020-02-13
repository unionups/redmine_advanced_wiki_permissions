class WikiPermissionsController < ApplicationController
  include WikiPermissionsHelper
  unloadable

  before_action :deny_access_for_wiki_page

  def new
    if params[:member] &&
       params[:member][:user_ids] &&
       (params[:member][:permissions] || params[:member][:bans])
      @principals = Principal.where(id: params[:member][:user_ids])
      @principals -= @wiki_page.principals_with_permissions
      create_wpps
      @wiki_page.reload
      @wiki_page_permissions = @wiki_page.permissions
    end
    respond_to :js
  end

  def update
    @wpp = WikiPagePermission.find(params[:wpp_id])
    @principal = @wpp.principal
    if params[:member] && params[:member][:permissions]
      @deleted_permissions = @wpp.permissions - params[:member][:permissions].map(&:to_sym)
    end
    if params[:member] && (params[:member][:permissions] || params[:member][:bans])
      update_wpp
    end
    @wiki_page_permissions = @wiki_page.permissions

    if @deleted_permissions.try(:any?) && @principal.class == User && @principal.delegate_permission_exist?(@project)
      @dp = @principal.delegate_permission_for(@project)
      @wpps = @wiki_page.permissions.find_by(delegate_permission_id: @dp.id)
    end
    respond_to :js
  end

  def destroy
    wpp = WikiPagePermission.find(params[:wpp_id])
    principal = wpp.principal
    wpp.destroy
    if principal.class == User && principal.delegate_permission_exist?(@project)
      @dp = principal.delegate_permission_for(@project)
      @wpps = @wiki_page.permissions.find_by(delegate_permission_id: @dp.id)
    end
    @wiki_page_permissions = @wiki_page.permissions unless @wpps.present? && @wpps.any?
    respond_to :js
  end

  def update_following_wpps
    @wpps = @wiki_page.permissions.find_by(delegate_permission_id: params[:dp_id])
    deleted_permissions = params[:deleted_permissions].map(&:to_sym)
    if @wpps.any?
      @wpps.each do |wpp|
        @wpp.permissions -= deleted_permissions
        @wpp.save
      end
    end
    @wiki_page_permissions = @wiki_page.permissions
    @principal_id = params[:principal_id]
    respond_to :js
  end

  def destroy_following_wpps
    wpps = @wiki_page.permissions.find_by(delegate_permission_id: params[:dp_id])
    wpps.each { |wpp| wpp.destroy } if wpps.any?
    @wiki_page_permissions = @wiki_page.permissions
    respond_to :js
  end

  def update_page
    @wiki_page_permissions = @wiki_page.permissions
    @principal_id = params[:principal_id] 
    respond_to :js
  end

  def autocomplete_for_member
      user = User.current
      delete_ids = @wiki_page.permissions.map(&:principal_id)
      @principals = Principal.active.like(params[:q])
      @principals = @principals.to_a.delete_if {|principal| delete_ids.include?(principal.id)}
      unless user.wiki_manager?(@project)
        user.delegate_permission_for(@project)
        @principals &= user.principals_for_delegate(@project)
      end
      @principals = @principals[0..100]
      render :layout => false
  end

  private
  def deny_access_for_wiki_page
    if params[:project_id] && params[:id]
      @project = Project.find(params[:project_id])
      wiki = @project.wiki
      @wiki_page = wiki.find_page(params[:id])
      deny_access unless User.current.allowed_to_manage_wiki_rights?(@wiki_page)
    else
      deny_access
    end
  end
end

