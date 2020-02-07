require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  should "fix action for wiki page permissions actions" do
    assert_equal :edit_wiki_pages, User.new.fix_action_for_wiki_page_permissions('edit')
    assert_equal :view_wiki_edits, User.new.fix_action_for_wiki_page_permissions('history')
    assert_equal :delete_wiki_pages, User.new.fix_action_for_wiki_page_permissions('destroy')
    assert_equal :rename_wiki_pages, User.new.fix_action_for_wiki_page_permissions('rename')
    assert_equal :protect_wiki_pages, User.new.fix_action_for_wiki_page_permissions('protect')
  end

  context "#allowed_to?" do
    should "return true if redmine_advanced_wiki_permissions enabled and we can go to 'wiki' controller" do
      @project = Project.generate!
      @user = User.generate!
      action = { :controller => 'wiki' }
      assert @user.allowed_to?(action, @project)
    end

    should "return value from original User#allowed_to?" do
      @project = Project.generate!(:is_public => false)
      @project.enabled_module_names = [:wiki]
      @user = User.generate!
      action = { :controller => 'wiki' }
      assert !@user.allowed_to?(action, @project)
    end
  end

  context "#wiki_allowed_to?" do
    should "return true for admin user" do
      @wiki_page = WikiPage.generate!
      @user = User.generate!(:admin => true)
      assert @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages)
    end

    context "access through groups" do
      setup do
        @wiki_page = WikiPage.generate!
        @user = User.generate!
        @group = Group.generate!(:users => [@user])

        @wpp = WikiPagePermission.new
        @wpp.principal = @group
        @wpp.wiki_page = @wiki_page
        @wpp.permissions = [:edit_wiki_pages]
        @wpp.save!
      end

      should "allow access through groups" do
        assert @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages)
      end

      should "deny access through groups" do
        assert !@user.wiki_allowed_to?(@wiki_page, :manage_wiki)
      end
    end

    context "#wiki_allowed_to? with WikiPage" do
      context "WikiPage has permissions" do
        should "allow action if user has permission for it" do
          @wiki_page = WikiPage.generate!
          @user = User.generate!

          @wpp = WikiPagePermission.new
          @wpp.principal = @user
          @wpp.wiki_page = @wiki_page
          @wpp.permissions = [:edit_wiki_pages]
          @wpp.save!

          assert @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages)
        end

        should "allow all actions if user has :manage_wiki permission for this wiki page" do
          @wiki_page = WikiPage.generate!
          @user = User.generate!

          @wpp = WikiPagePermission.new
          @wpp.principal = @user
          @wpp.wiki_page = @wiki_page
          @wpp.permissions = [:manage_wiki]
          @wpp.save!

          assert @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages)
        end

        should "allow all action if user has :manage_wiki_rights in this project" do
          @project = Project.generate!
          @wiki = Wiki.generate!(:project => @project)
          @project.wiki = @wiki
          @project.save!
          @project.reload
          @wiki_page = WikiPage.generate!(:wiki => @wiki)
          @user = User.generate!
          @role = Role.generate!(:permissions => [:manage_wiki_rights])
          @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])

          @wpp = WikiPagePermission.new
          @wpp.principal = @user
          @wpp.wiki_page = @wiki_page
          @wpp.permissions = [:view_wiki_pages]
          @wpp.save!

          assert @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages)
        end

        should "not allow action if user hasn't permissions" do
          @wiki_page = WikiPage.generate!
          @user = User.generate!
          @another_user = User.generate!

          @wpp = WikiPagePermission.new
          @wpp.principal = @another_user
          @wpp.wiki_page = @wiki_page
          @wpp.permissions = [:manage_wiki]
          @wpp.save!

          assert !@user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages)
        end
      end

      context "WikiPage doesn't have permissions" do
        should "allow all for user with :manage_wiki_rights in this project" do
          @project = Project.generate!
          @wiki = Wiki.generate!(:project => @project)
          @project.wiki = @wiki
          @project.save!
          @project.reload
          @wiki_page = WikiPage.generate!(:wiki => @wiki)
          @user = User.generate!
          @role = Role.generate!(:permissions => [:manage_wiki_rights])
          @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])

          assert @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages)
        end

        should "not allow if action :manage_wiki (this is for wiki pages permissions, not project)" do
          @wiki = Wiki.generate!
          @user = User.generate!

          assert !@user.wiki_allowed_to?(@wiki_page, :manage_wiki)
        end

        should "return value from original allowed_to?" do
          @project = Project.generate!
          @wiki = Wiki.generate!(:project => @project)
          @project.wiki = @wiki
          @project.save!
          @project.reload
          @wiki_page = WikiPage.generate!(:wiki => @wiki)
          @user = User.generate!
          @role = Role.generate!(:permissions => [:edit_wiki_pages])
          @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])

          assert @user.wiki_allowed_to?(@wiki_page, :edit_wiki_pages)
        end
      end
    end

    context "#wiki_allowed_to? with Project" do
      setup do
        @project = Project.generate!
        @wiki = Wiki.generate!(:project => @project)
        @project.wiki = @wiki
        @project.save!
        @project.reload
        @wiki_page1 = WikiPage.generate!(:wiki => @wiki)
        @wiki_page2 = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
      end

      should "allow export wiki pages for project" do
        @wpp1 = WikiPagePermission.new
        @wpp1.principal = @user
        @wpp1.wiki_page = @wiki_page1
        @wpp1.permissions = [:export_wiki_pages]
        @wpp1.save!

        @wpp2 = WikiPagePermission.new
        @wpp2.principal = @user
        @wpp2.wiki_page = @wiki_page2
        @wpp2.permissions = [:export_wiki_pages]
        @wpp2.save!

        assert @user.wiki_allowed_to?(@project, :export_wiki_pages)
      end

      should "not allow export wiki pages for project" do
        @wpp1 = WikiPagePermission.new
        @wpp1.principal = @user
        @wpp1.wiki_page = @wiki_page1
        @wpp1.permissions = [:export_wiki_pages]
        @wpp1.save!

        @wpp2 = WikiPagePermission.new
        @wpp2.principal = @user
        @wpp2.wiki_page = @wiki_page2
        @wpp2.permissions = [:edit_wiki_pages]
        @wpp2.save!

        assert !@user.wiki_allowed_to?(@project, :export_wiki_pages)
      end
    end
  end

  context "#allowed_to_manage_wiki?" do
    setup do
      @wiki_page = WikiPage.generate!
      @user = User.generate!
    end

    should "return true if user allowed to manage rights for wiki page" do
      @wpp = WikiPagePermission.new
      @wpp.principal = @user
      @wpp.wiki_page = @wiki_page
      @wpp.permissions = [:manage_wiki]
      @wpp.save!

      assert @user.allowed_to_manage_wiki?(@wiki_page)
    end

    should "return nil if user not allowed to manage rights for wiki page" do
      @wpp = WikiPagePermission.new
      @wpp.principal = @user
      @wpp.wiki_page = @wiki_page
      @wpp.permissions = [:edit_wiki_pages]
      @wpp.save!

      assert !@user.allowed_to_manage_wiki?(@wiki_page)
    end
  end
end

