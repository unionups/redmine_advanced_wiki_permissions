require File.expand_path('../../spec_helper', __FILE__)

describe WikiController, "routing" do
  it "should route right" do
    params_from(:get, '/projects/projectname/wiki/Wiki/permissions').should == {
                      :controller => 'wiki',
                      :action => 'permissions',
                      :project_id => 'projectname',
                      :id => 'Wiki' }
    params_from(:post, '/projects/projectname/wiki/Wiki/ignore_permissions').should == {
                       :controller => 'wiki',
                       :action => 'ignore_permissions',
                       :project_id => 'projectname',
                       :id => 'Wiki' }
  end
end

describe WikiController, "redmine_advanced_permission_plugin disabled" do
  context "and user is admin" do
    before(:each) do
      @project = Project.generate!
      @project.enabled_module_names = [:wiki]
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
      @user = User.generate!(:admin => true)
      @wiki_content = WikiContent.generate!(:page => @wiki_page, :author => @user, :text => 'h1. Demo')
      @wiki_page.reload
      User.stub!(:current).and_return(@user)
    end

    it "should allow view wiki page" do
      get :show, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow edit wiki page" do
      get :edit, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow update wiki page" do
      put :update, :id => @wiki_page.title,
                   :project_id => @project,
                   :content => {
                     :text => 'h1. Test',
                     :version => @wiki_page.content.version + 1 }
      response.should be_success
    end

    it "should allow rename wiki page" do
      post :rename, :id => @wiki_page.title,
                    :project_id => @project,
                    :wiki_page => {
                      :title => "NewWikiTitle",
                      :parent_id => "",
                      :redirect_existing_links => "1" }
      response.should redirect_to("/projects/#{@project.identifier}/wiki/NewWikiTitle")
    end

    it "should allow protect wiki page" do
      post :protect, :id => @wiki_page.title, :project_id => @project, :protected => 1
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}")
    end

    it "should allow view wiki page history" do
      get :history, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow destroy wiki page" do
      delete :destroy, :id => @wiki_page.title, :project_id => @project
      response.should redirect_to("/projects/#{@project.identifier}/wiki/index")
    end

    it "should allow export wiki page" do
      get :export, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should not allow view wiki page permissions" do
      get :permissions, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should not allow call ignore_permissions" do
      post :ignore_permissions, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
      response.should_not redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}/permissions")
    end
  end
end

describe WikiController, "redmine_advanced_permission_plugin enabled" do
  context "and user is admin" do
    before(:each) do
      @project = Project.generate!
      @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
      @user = User.generate!(:admin => true)
      @wiki_content = WikiContent.generate!(:page => @wiki_page, :author => @user, :text => 'h1. Demo')
      @wiki_page.reload
      User.stub!(:current).and_return(@user)
    end

    it "should allow view wiki page" do
      get :show, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow edit wiki page" do
      get :edit, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow update wiki page" do
      put :update, :id => @wiki_page.title,
                   :project_id => @project,
                   :content => {
                     :text => 'h1. Test',
                     :version => @wiki_page.content.version + 1 }
      response.should be_success
    end

    it "should allow rename wiki page" do
      post :rename, :id => @wiki_page.title,
                    :project_id => @project,
                    :wiki_page => {
                      :title => "NewWikiTitle",
                      :parent_id => "",
                      :redirect_existing_links => "1" }
      response.should redirect_to("/projects/#{@project.identifier}/wiki/NewWikiTitle")
    end

    it "should allow protect wiki page" do
      post :protect, :id => @wiki_page.title, :project_id => @project, :protected => 1
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}")
    end

    it "should allow view wiki page history" do
      get :history, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow destroy wiki page" do
      delete :destroy, :id => @wiki_page.title, :project_id => @project
      response.should redirect_to("/projects/#{@project.identifier}/wiki/index")
    end

    it "should allow export wiki page" do
      get :export, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow view wiki page permissions" do
      get :permissions, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow call ignore_permissions" do
      post :ignore_permissions, :id => @wiki_page.title, :project_id => @project,
           :ignore_permissions => true
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}/permissions")
    end
  end

  context "and user has :manage_wiki_rights in project" do
    before(:each) do
      @project = Project.generate!
      @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
      @user = User.generate!
      @wiki_content = WikiContent.generate!(:page => @wiki_page, :author => @user, :text => 'h1. Demo')
      @wiki_page.reload
      User.stub!(:current).and_return(@user)
      @role = Role.generate!(:permissions => [:manage_wiki_rights])
      @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])
    end

    it "should allow view wiki page" do
      get :show, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow edit wiki page" do
      get :edit, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow update wiki page" do
      put :update, :id => @wiki_page.title,
                   :project_id => @project,
                   :content => {
                     :text => 'h1. Test',
                     :version => @wiki_page.content.version + 1 }
      response.should be_success
    end

    it "should allow rename wiki page" do
      post :rename, :id => @wiki_page.title,
                    :project_id => @project,
                    :wiki_page => {
                      :title => "NewWikiTitle",
                      :parent_id => "",
                      :redirect_existing_links => "1" }
      response.should redirect_to("/projects/#{@project.identifier}/wiki/NewWikiTitle")
    end

    it "should allow protect wiki page" do
      post :protect, :id => @wiki_page.title, :project_id => @project, :protected => 1
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}")
    end

    it "should allow view wiki page history" do
      get :history, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow destroy wiki page" do
      delete :destroy, :id => @wiki_page.title, :project_id => @project
      response.should redirect_to("/projects/#{@project.identifier}/wiki/index")
    end

    it "should allow export wiki page" do
      get :export, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow view wiki page permissions" do
      get :permissions, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow call ignore_permissions" do
      post :ignore_permissions, :id => @wiki_page.title, :project_id => @project,
           :ignore_permissions => true
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}/permissions")
    end
  end

  context "and user has :manage_wiki for wiki page" do
    before(:each) do
      @project = Project.generate!
      @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
      @user = User.generate!
      @wiki_content = WikiContent.generate!(:page => @wiki_page, :author => @user, :text => 'h1. Demo')
      @wiki_page.reload
      User.stub!(:current).and_return(@user)
      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => [:manage_wiki])
    end

    it "should allow view wiki page" do
      get :show, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow edit wiki page" do
      get :edit, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow update wiki page" do
      put :update, :id => @wiki_page.title,
                   :project_id => @project,
                   :content => {
                     :text => 'h1. Test',
                     :version => @wiki_page.content.version + 1 }
      response.should be_success
    end

    it "should allow rename wiki page" do
      post :rename, :id => @wiki_page.title,
                    :project_id => @project,
                    :wiki_page => {
                      :title => "NewWikiTitle",
                      :parent_id => "",
                      :redirect_existing_links => "1" }
      response.should redirect_to("/projects/#{@project.identifier}/wiki/NewWikiTitle")
    end

    it "should allow protect wiki page" do
      post :protect, :id => @wiki_page.title, :project_id => @project, :protected => 1
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}")
    end

    it "should allow view wiki page history" do
      get :history, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow destroy wiki page" do
      delete :destroy, :id => @wiki_page.title, :project_id => @project
      response.should redirect_to("/projects/#{@project.identifier}/wiki/index")
    end

    it "should allow export wiki page" do
      get :export, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow view wiki page permissions" do
      get :permissions, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow call ignore_permissions" do
      post :ignore_permissions, :id => @wiki_page.title, :project_id => @project,
           :ignore_permissions => true
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}/permissions")
    end
  end

  context "and user has permissions for wiki page" do
    before(:each) do
      @project = Project.generate!
      @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
      @user = User.generate!
      @wiki_content = WikiContent.generate!(:page => @wiki_page, :author => @user, :text => 'h1. Demo')
      @wiki_page.reload
      User.stub!(:current).and_return(@user)
      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => [:view_wiki_pages,
                                                         :edit_wiki_pages,
                                                         :delete_wiki_pages,
                                                         :export_wiki_pages,
                                                         :view_wiki_edits,
                                                         :rename_wiki_pages,
                                                         :delete_wiki_pages_attachments,
                                                         :protect_wiki_pages])
    end

    it "should allow view wiki page" do
      get :show, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow edit wiki page" do
      get :edit, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow update wiki page" do
      put :update, :id => @wiki_page.title,
                   :project_id => @project,
                   :content => {
                     :text => 'h1. Test',
                     :version => @wiki_page.content.version + 1 }
      response.should be_success
    end

    it "should allow rename wiki page" do
      post :rename, :id => @wiki_page.title,
                    :project_id => @project,
                    :wiki_page => {
                      :title => "NewWikiTitle",
                      :parent_id => "",
                      :redirect_existing_links => "1" }
      response.should redirect_to("/projects/#{@project.identifier}/wiki/NewWikiTitle")
    end

    it "should allow protect wiki page" do
      post :protect, :id => @wiki_page.title, :project_id => @project, :protected => 1
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}")
    end

    it "should allow view wiki page history" do
      get :history, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow destroy wiki page" do
      delete :destroy, :id => @wiki_page.title, :project_id => @project
      response.should redirect_to("/projects/#{@project.identifier}/wiki/index")
    end

    it "should allow export wiki page" do
      get :export, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should not allow view wiki page permissions" do
      get :permissions, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should not allow call ignore_permissions" do
      post :ignore_permissions, :id => @wiki_page.title, :project_id => @project,
           :ignore_permissions => true
      response.should_not be_success
      response.should_not redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}/permissions")
    end
  end

  context "and user has permissions in project for wiki pages" do
    before(:each) do
      @project = Project.generate!
      @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
      @user = User.generate!
      @wiki_content = WikiContent.generate!(:page => @wiki_page, :author => @user, :text => 'h1. Demo')
      @wiki_page.reload
      User.stub!(:current).and_return(@user)
      @role = Role.generate!(:permissions => [:rename_wiki_pages,
                                              :delete_wiki_pages,
                                              :view_wiki_pages,
                                              :export_wiki_pages,
                                              :view_wiki_edits,
                                              :edit_wiki_pages,
                                              :delete_wiki_pages_attachments,
                                              :protect_wiki_pages])
      @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])
    end

    it "should allow view wiki page" do
      get :show, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow edit wiki page" do
      get :edit, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow update wiki page" do
      put :update, :id => @wiki_page.title,
                   :project_id => @project,
                   :content => {
                     :text => 'h1. Test',
                     :version => @wiki_page.content.version + 1 }
      response.should be_success
    end

    it "should allow rename wiki page" do
      post :rename, :id => @wiki_page.title,
                    :project_id => @project,
                    :wiki_page => {
                      :title => "NewWikiTitle",
                      :parent_id => "",
                      :redirect_existing_links => "1" }
      response.should redirect_to("/projects/#{@project.identifier}/wiki/NewWikiTitle")
    end

    it "should allow protect wiki page" do
      post :protect, :id => @wiki_page.title, :project_id => @project, :protected => 1
      response.should redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}")
    end

    it "should allow view wiki page history" do
      get :history, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should allow destroy wiki page" do
      delete :destroy, :id => @wiki_page.title, :project_id => @project
      response.should redirect_to("/projects/#{@project.identifier}/wiki/index")
    end

    it "should allow export wiki page" do
      get :export, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should not allow view wiki page permissions" do
      get :permissions, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should not allow call ignore_permissions" do
      post :ignore_permissions, :id => @wiki_page.title, :project_id => @project,
           :ignore_permissions => true
      response.should_not be_success
      response.should_not redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}/permissions")
    end
  end

  context "and user has no permissions in project for wiki pages" do
    before(:each) do
      @project = Project.generate!
      @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
      @user = User.generate!
      @wiki_content = WikiContent.generate!(:page => @wiki_page, :author => @user, :text => 'h1. Demo')
      @wiki_page.reload
    end

    it "should not allow view wiki page" do
      get :show, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should not allow edit wiki page" do
      get :edit, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should not allow update wiki page" do
      put :update, :id => @wiki_page.title,
                   :project_id => @project,
                   :content => {
                     :text => 'h1. Test',
                     :version => @wiki_page.content.version + 1 }
      response.should_not be_success
    end

    it "should not allow rename wiki page" do
      post :rename, :id => @wiki_page.title,
                    :project_id => @project,
                    :wiki_page => {
                      :title => "NewWikiTitle",
                      :parent_id => "",
                      :redirect_existing_links => "1" }
      response.should_not be_success
      response.should_not redirect_to("/projects/#{@project.identifier}/wiki/NewWikiTitle")
    end

    it "should not allow protect wiki page" do
      post :protect, :id => @wiki_page.title, :project_id => @project, :protected => 1
      response.should_not be_success
      response.should_not redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}")
    end

    it "should not allow view wiki page history" do
      get :history, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should not allow destroy wiki page" do
      delete :destroy, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
      response.should_not redirect_to("/projects/#{@project.identifier}/wiki/index")
    end

    it "should not allow export wiki page" do
      get :export, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should not allow view wiki page permissions" do
      get :permissions, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should not allow call ignore_permissions" do
      post :ignore_permissions, :id => @wiki_page.title, :project_id => @project,
           :ignore_permissions => true
      response.should_not be_success
      response.should_not redirect_to("/projects/#{@project.identifier}/wiki/#{@wiki_page.title}/permissions")
    end
  end
end

