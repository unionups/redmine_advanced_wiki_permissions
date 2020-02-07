require File.expand_path('../../spec_helper', __FILE__)

describe WikiPermissionsController do
  it "should route right" do
    params_from(:post, '/projects/projectname/wiki/Wiki/permissions/destroy').should == {
                       :controller => 'wiki_permissions',
                       :action => 'destroy',
                       :project_id => 'projectname',
                       :id => 'Wiki' }
    params_from(:post, '/projects/projectname/wiki/Wiki/permissions/update').should == {
                       :controller => 'wiki_permissions',
                       :action => 'update',
                       :project_id => 'projectname',
                       :id => 'Wiki' }
    params_from(:post, '/projects/projectname/wiki/Wiki/permissions/autocomplete_for_member').should == {
                       :controller => 'wiki_permissions',
                       :action => 'autocomplete_for_member',
                       :project_id => 'projectname',
                       :id => 'Wiki' }
  end

  context "#new" do
    before(:each) do
      @project = Project.generate!
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
    end

    it "should deny without wiki_page and project" do
      post :new
      response.should_not be_success
    end

    it "should deny for unauthorized user" do
      post :new, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should allow for authorized user with permission" do
      @user = User.generate!
      @another_user = User.generate!
      User.stub!(:current).and_return(@user)
      User.current.should_receive(:allowed_to_manage_wiki?).with(@wiki_page).and_return(true)

      post :new, :id => @wiki_page.title,
                 :project_id => @project,
                 :principal_id => @user,
                 :member => {
                   :user_ids => [@user.id, @another_user.id],
                   :permissions => WikiPagePermission::PERMS.each.map {|p| p.to_s}}
      response.should be_success
    end

    it "should deny for authorized user without permission" do
      @user = User.generate!
      User.stub!(:current).and_return(@user)
      User.current.should_receive(:allowed_to_manage_wiki?).with(@wiki_page).and_return(false)

      post :new, :id => @wiki_page.title,
                 :project_id => @project,
                 :principal_id => @user,
                 :member => {
                   :user_ids => [@user.id],
                   :permissions => WikiPagePermission::PERMS.each.map {|p| p.to_s}}
      response.should_not be_success
    end
  end

  context "#update" do
    before(:each) do
      @project = Project.generate!
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
    end

    it "should deny without wiki_page and project" do
      post :update
      response.should_not be_success
    end

    it "should deny for unauthorized user" do
      post :update, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should allow for authorized user with permission" do
      @user = User.generate!
      @another_user = User.generate!
      User.stub!(:current).and_return(@user)
      User.current.should_receive(:allowed_to_manage_wiki?).with(@wiki_page).and_return(true)

      post :update, :id => @wiki_page.title,
                    :project_id => @project,
                    :principal_id => @user,
                    :member => {
                      :user_ids => [@user.id, @another_user.id],
                      :permissions => WikiPagePermission::PERMS.each.map {|p| p.to_s}}
      response.should be_success
    end

    it "should deny for authorized user without permission" do
      @user = User.generate!
      User.stub!(:current).and_return(@user)
      User.current.should_receive(:allowed_to_manage_wiki?).with(@wiki_page).and_return(false)

      post :update, :id => @wiki_page.title,
                    :project_id => @project,
                    :principal_id => @user,
                    :member => {
                      :user_ids => [@user.id],
                      :permissions => WikiPagePermission::PERMS.each.map {|p| p.to_s}}
      response.should_not be_success
    end
  end

  context "#destroy" do
    before(:each) do
      @project = Project.generate!
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
    end

    it "should deny without wiki_page and project" do
      post :destroy
      response.should_not be_success
    end

    it "should deny for unauthorized user" do
      post :destroy, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should allow for authorized user with permission" do
      @user = User.generate!
      User.stub!(:current).and_return(@user)
      User.current.should_receive(:allowed_to_manage_wiki?).with(@wiki_page).and_return(true)

      post :destroy, :id => @wiki_page.title, :project_id => @project, :principal_id => @user
      response.should be_success
    end

    it "should deny for authorized user without permission" do
      @user = User.generate!
      User.stub!(:current).and_return(@user)
      User.current.should_receive(:allowed_to_manage_wiki?).with(@wiki_page).and_return(false)

      post :destroy, :id => @wiki_page.title, :project_id => @project, :principal_id => @user
      response.should_not be_success
    end
  end

  context "#autocomplete_for_member" do
    before(:each) do
      @project = Project.generate!
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
    end

    it "should deny without wiki_page and project" do
      post :autocomplete_for_member
      response.should_not be_success
    end

    it "should deny for unauthorized user" do
      post :autocomplete_for_member, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end

    it "should allow for authorized user with permission" do
      @user = User.generate!
      User.stub!(:current).and_return(@user)
      User.current.should_receive(:allowed_to_manage_wiki?).with(@wiki_page).and_return(true)

      post :autocomplete_for_member, :id => @wiki_page.title, :project_id => @project
      response.should be_success
    end

    it "should deny for authorized user without permission" do
      @user = User.generate!
      User.stub!(:current).and_return(@user)
      User.current.should_receive(:allowed_to_manage_wiki?).with(@wiki_page).and_return(false)

      post :autocomplete_for_member, :id => @wiki_page.title, :project_id => @project
      response.should_not be_success
    end
  end
end

