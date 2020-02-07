require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  it "should fix action for wiki page permissions actions" do
    User.new.fix_action_for_wiki_page_permissions('edit').should == :edit_wiki_pages
    User.new.fix_action_for_wiki_page_permissions('history').should == :view_wiki_edits
    User.new.fix_action_for_wiki_page_permissions('destroy').should == :delete_wiki_pages
    User.new.fix_action_for_wiki_page_permissions('rename').should == :rename_wiki_pages
    User.new.fix_action_for_wiki_page_permissions('protect').should == :protect_wiki_pages
  end

  context "#allowed_to?" do
    it "should return true if redmine_advanced_wiki_permissions enabled and we can go to 'wiki' controller" do
      @project = Project.generate!
      @user = User.generate!
      action = { :controller => 'wiki' }
      @user.allowed_to?(action, @project).should be_true
    end

    it "should return value from original User#allowed_to?" do
      @project = Project.generate!(:is_public => false)
      @project.enabled_module_names = [:wiki]
      @user = User.generate!
      action = { :controller => 'wiki' }
      @user.allowed_to?(action, @project).should_not be_true
    end
  end

  context "#wiki_allowed_to?" do
    it "should return true for admin user" do
      @wiki_page = WikiPage.generate!
      @user = User.generate!(:admin => true)
      @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages).should be_true
    end

    context "access through groups" do
      before(:each) do
        @wiki_page = WikiPage.generate!
        @user = User.generate!
        @group = Group.generate!(:users => [@user])
        @wpp = WikiPagePermission.create!(:principal => @group,
                                          :wiki_page => @wiki_page,
                                          :permissions => [:edit_wiki_pages])
      end

      it "should allow access through groups" do
        @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages).should be_true
      end

      it "should deny access through groups" do
        @user.wiki_allowed_to?(@wiki_page, :manage_wiki).should_not be_true
      end
    end

    context "#wiki_allowed_to? with WikiPage" do
      context "WikiPage has permissions" do
        it "should allow action if user has permission for it" do
          @wiki_page = WikiPage.generate!
          @user = User.generate!
          @wpp = WikiPagePermission.create!(:principal => @user,
                                            :wiki_page => @wiki_page,
                                            :permissions => [:edit_wiki_pages])

          @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages).should be_true
        end

        it "should allow all actions if user has :manage_wiki permission for this wiki page" do
          @wiki_page = WikiPage.generate!
          @user = User.generate!
          @wpp = WikiPagePermission.create!(:principal => @user,
                                            :wiki_page => @wiki_page,
                                            :permissions => [:manage_wiki])

          @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages).should be_true
        end

        it "should allow all action if user has :manage_wiki_rights in this project" do
          @project = Project.generate!
          @wiki = Wiki.generate!(:project => @project)
          @project.wiki = @wiki
          @project.save!
          @project.reload
          @wiki_page = WikiPage.generate!(:wiki => @wiki)
          @user = User.generate!
          @role = Role.generate!(:permissions => [:manage_wiki_rights])
          @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])
          @wpp = WikiPagePermission.create!(:principal => @user,
                                            :wiki_page => @wiki_page,
                                            :permissions => [:view_wiki_pages])

          @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages).should be_true
        end

        it "should not allow action if user hasn't permissions" do
          @wiki_page = WikiPage.generate!
          @user = User.generate!
          @another_user = User.generate!
          @wpp = WikiPagePermission.create!(:principal => @another_user,
                                            :wiki_page => @wiki_page,
                                            :permissions => [:manage_wiki])

          @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages).should_not be_true
        end
      end

      context "WikiPage doesn't have permissions" do
        it "should allow all for user with :manage_wiki_rights in this project" do
          @project = Project.generate!
          @wiki = Wiki.generate!(:project => @project)
          @project.wiki = @wiki
          @project.save!
          @project.reload
          @wiki_page = WikiPage.generate!(:wiki => @wiki)
          @user = User.generate!
          @role = Role.generate!(:permissions => [:manage_wiki_rights])
          @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])

          @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages).should be_true
        end

        it "should not allow if action :manage_wiki (this is for wiki pages permissions, not project)" do
          @wiki = Wiki.generate!
          @user = User.generate!

          @user.wiki_allowed_to?(@wiki_page, :manage_wiki).should_not be_true
        end

        it "should return value from original allowed_to?" do
          @project = Project.generate!
          @wiki = Wiki.generate!(:project => @project)
          @project.wiki = @wiki
          @project.save!
          @project.reload
          @wiki_page = WikiPage.generate!(:wiki => @wiki)
          @user = User.generate!
          @role = Role.generate!(:permissions => [:edit_wiki_pages])
          @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])

          @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages).should be_true
        end
      end
    end

    context "#wiki_allowed_to? with Project" do
      before(:each) do
        @project = Project.generate!
        @wiki = Wiki.generate!(:project => @project)
        @project.wiki = @wiki
        @project.save!
        @project.reload
        @wiki_page1 = WikiPage.generate!(:wiki => @wiki)
        @wiki_page2 = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
      end

      it "should allow export wiki pages for project" do
        @wpp1 = WikiPagePermission.create!(:principal => @user,
                                           :wiki_page => @wiki_page1,
                                           :permissions => [:export_wiki_pages])
        @wpp2 = WikiPagePermission.create!(:principal => @user,
                                           :wiki_page => @wiki_page2,
                                           :permissions => [:export_wiki_pages])

        @user.wiki_allowed_to?(@project, :export_wiki_pages).should be_true
      end

      it "should not allow export wiki pages for project" do
        @wpp1 = WikiPagePermission.create!(:principal => @user,
                                           :wiki_page => @wiki_page1,
                                           :permissions => [:export_wiki_pages])
        @wpp2 = WikiPagePermission.create!(:principal => @user,
                                           :wiki_page => @wiki_page2,
                                           :permissions => [:edit_wiki_pages])

        @user.wiki_allowed_to?(@project, :export_wiki_pages).should_not be_true
      end
    end
  end

  context "#allowed_to_manage_wiki?" do
    before(:each) do
      @wiki_page = WikiPage.generate!
      @user = User.generate!
    end

    it "should return true if user allowed to manage rights for wiki page" do
      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => [:manage_wiki])

      @user.allowed_to_manage_wiki?(@wiki_page).should be_true
    end

    it "should return nil if user not allowed to manage rights for wiki page" do
      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => [:edit_wiki_pages])

      @user.allowed_to_manage_wiki?(@wiki_page).should_not be_true
    end
  end

  context "#permission_exist?" do
    before(:each) do
      @user = User.generate!
      @wiki_page = WikiPage.generate!
    end

    it "should return true if permissions for wiki page exists" do
      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => [:view_wiki_pages])

      @user.permission_exist?(@wiki_page).should be_true
    end

    it "should retrun false if permissions for wiki page not exists" do
      @user.permission_exist?(@wiki_page).should_not be_true
    end
  end

  context "#allowed_to_ignore_permissions" do
    it "should return true if user is admin?" do
      @user = User.generate!(:admin => true)
      @wiki_page = WikiPage.generate!

      @user.allowed_to_ignore_permissions(@wiki_page).should be_true
    end

    it "should return true if user has :manage_wiki_rights in the project" do
      @project = Project.generate!
      @wiki = Wiki.generate!(:project => @project)
      @project.wiki = @wiki
      @project.save!
      @project.reload
      @wiki_page = WikiPage.generate!(:wiki => @wiki)
      @user = User.generate!
      @role = Role.generate!(:permissions => [:manage_wiki_rights])
      @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])

      @user.allowed_to_ignore_permissions(@wiki_page).should be_true
    end

    it "should return true if user has :manage_wiki for wiki page" do
      @user = User.generate!
      @wiki_page = WikiPage.generate!

      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => [:manage_wiki])

      @user.allowed_to_ignore_permissions(@wiki_page).should be_true
    end

    it "should return false if user doesn't have permissions" do
      @user = User.generate!
      @wiki_page = WikiPage.generate!

      @user.allowed_to_ignore_permissions(@wiki_page).should_not be_true
    end
  end
end

