module WikiPermissionsHelper
  # based on ApplicationHelper#principals_check_box_tags
  def wiki_permissions_check_box_tags(name, principals)
    s = ''
    principals.sort.each do |principal|
      s << "<label>#{ check_box_tag name, principal.id, false } #{h principal}</label>\n"
    end
    s.html_safe
  end

  def delegate_list(user = User.current)
    return WikiPagePermission::PERMS if user.wiki_manager?(@project)
    permissions = []
    return permissions unless user.allowed_to_manage_wiki_rights?(@wiki_page)
    (WikiPagePermission::PERMS - [:delegate_permissions]).each do |permission|
      permissions << permission if user.wiki_allowed_to?(@wiki_page, permission)
    end
    permissions
  end

  def disabled_permissions(user)
    permissions_from_groups = (user.class == User) ? user.permissions_from_groups(@wiki_page) : []
    delegate_list & (user.permissions_from(@project) | permissions_from_groups)
  end

  # User can't take away permissions and bans, that he hasn't
  def create_wpps
    @principals.each do |principal|
      wpp = WikiPagePermission.new
      wpp.principal = principal
      wpp.wiki_page = @wiki_page
      dp = User.current.delegate_permission_for(@project)
      wpp.delegate_permission = dp if dp
      if @wiki_page.ignore_permissions?
        wpp.permissions = params[:member][:permissions] ? params[:member][:permissions].map(&:to_sym) : []
        wpp.bans = []
      else
        wpp.permissions = params[:member][:permissions] ? create_permissions(principal) : []
        wpp.bans = params[:member][:bans] ? create_bans(principal) : []
      end
      wpp.save
    end
  end

  def update_wpp
    @wpp.delegate_permission = User.current.delegate_permission_exist?(@project) ? User.current.delegate_permission_for(@project) : nil
    if @wiki_page.ignore_permissions?
      @wpp.permissions = @wpp.permissions - delegate_list + (params[:member][:permissions] ? params[:member][:permissions].map(&:to_sym) : [])
      @wpp.bans = []
    else
      @wpp.permissions = @wpp.permissions - delegate_list + (params[:member][:permissions] ? create_permissions(@principal) : [])
      @wpp.bans = @wpp.bans - delegate_list + (params[:member][:bans] ? create_bans(@principal) : [])
    end
    @wpp.save
  end

  def create_permissions(user)
    params[:member][:permissions].map(&:to_sym) - user.permissions_from(@project)
  end

  def create_bans(user)
    permissions_from_groups = (user.class == User) ? user.permissions_from_groups(@wiki_page) : []
    params[:member][:bans].map(&:to_sym) & (user.permissions_from(@project) | permissions_from_groups)
  end

  def permissions_to_s(permissions)
    str = ''
    permissions.each do |permission|
      str += ', ' unless str == ''
      str += h(l("label_" + permission.to_s))
    end
    str
  end

  # WikiPagePermissions for this page, which current user can see
  def visible_permissions(user = User.current)
    return @wiki_page_permissions if user.wiki_manager?(@project)
    dp = user.delegate_permission_for(@project)
    @wiki_page_permissions.select{|wpp| wpp if dp.principals_for_delegate.include?(wpp.principal)}
  end
end
