require File.dirname(__FILE__) + '/../test_helper'

class WikiPageTest < ActiveSupport::TestCase
  should_have_many :permissions

  context "without redmine_advanced_wiki_permissions" do
    context "user without role :protect_wiki_pages" do
      setup do
        @project = Project.generate!
        @project.enabled_module_names = [:wiki]
        @wiki = Wiki.generate!(:project => @project)
        @wiki_page = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
      end

      should "allow user edit wiki page un-protected wiki page" do
        @wiki_page.update_attribute(:protected, false)
        assert @wiki_page.editable_by?(@user)
      end

      should "not allow user edit wiki page protected wiki page" do
        @wiki_page.update_attribute(:protected, true)
        assert !@wiki_page.editable_by?(@user)
      end
    end

    context "user with role :protect_wiki_pages in project" do
      should "allow edit protected wiki page" do
        @project = Project.generate!
        @project.enabled_module_names = [:wiki]
        @wiki = Wiki.generate!(:project => @project)
        @wiki_page = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
        @wiki_page.update_attribute(:protected, true)
        @role = Role.generate!(:permissions => [:protect_wiki_pages])
        @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])

        assert @wiki_page.editable_by?(@user)
      end
    end
  end

  context "with redmine_advanced_wiki_permissions" do
    context "wiki page without wiki page permissions" do
      setup do
        @project = Project.generate!
        @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
        @wiki = Wiki.generate!(:project => @project)
        @wiki_page = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
      end

      should "allow user edit un-protected wiki page" do
        @wiki_page.update_attribute(:protected, false)
        assert @wiki_page.editable_by?(@user)
      end

      should "not allow user edit protected wiki page" do
        @wiki_page.update_attribute(:protected, true)
        assert !@wiki_page.editable_by?(@user)
      end
    end

    context "wiki page with wiki page permissions" do
      setup do
        @project = Project.generate!
        @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
        @wiki = Wiki.generate!(:project => @project)
        @wiki_page = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
      end

      should "allow user edit wiki page if user has permissions" do
        @wpp = WikiPagePermission.new
        @wpp.principal = @user
        @wpp.wiki_page = @wiki_page
        @wpp.permissions = [:protect_wiki_pages]
        @wpp.save!

        @wiki_page.update_attribute(:protected, true)
        assert @wiki_page.editable_by?(@user)
      end

      should "not allow user edit wiki page without permissions for it" do
        @another_user = User.generate!

        @wpp = WikiPagePermission.new
        @wpp.principal = @another_user
        @wpp.wiki_page = @wiki_page
        @wpp.permissions = [:protect_wiki_pages]
        @wpp.save!

        @wiki_page.update_attribute(:protected, true)
        assert !@wiki_page.editable_by?(@user)
      end
    end
  end
end

