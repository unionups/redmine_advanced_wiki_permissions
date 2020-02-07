require File.dirname(__FILE__) + '/../spec_helper'

describe WikiPage do
  it { should have_many :permissions }

  it "should validate :ignore_permissions" do
    @wiki_page = WikiPage.new
    @wiki_page.wiki = Wiki.generate!
    @wiki_page.title = 'Test'
    @wiki_page.ignore_permissions = false
    @wiki_page.save.should be_true

    @wiki_page.ignore_permissions = true
    @wiki_page.save.should be_true

    @wiki_page.ignore_permissions = nil
    @wiki_page.save.should be_true
  end

  context "WikiPage#ignore_permissions?" do
    it "should return true if WikiPage.ignore_permission is true" do
      @wiki_page = WikiPage.generate!(:ignore_permissions => true)
      @wiki_page.ignore_permissions?.should be_true
    end

    it "should return false if WikiPage.ignore_permissions is not true" do
      @wiki_page = WikiPage.generate!
      @wiki_page.ignore_permissions?.should_not be_true
    end
  end

  context "without redmine_advanced_wiki_permissions" do
    context "user without role :protect_wiki_pages" do
      before(:each) do
        @project = Project.generate!
        @project.enabled_module_names = [:wiki]
        @wiki = Wiki.generate!(:project => @project)
        @wiki_page = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
      end

      it "should allow user edit wiki page un-protected wiki page" do
        @wiki_page.update_attribute(:protected, false)
        @wiki_page.editable_by?(@user).should be_true
      end

      it "should not allow user edit wiki page protected wiki page" do
        @wiki_page.update_attribute(:protected, true)
        @wiki_page.editable_by?(@user).should be_false
      end
    end

    context "user with role :protect_wiki_pages in project" do
      it "should allow edit protected wiki page" do
        @project = Project.generate!
        @project.enabled_module_names = [:wiki]
        @wiki = Wiki.generate!(:project => @project)
        @wiki_page = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
        @wiki_page.update_attribute(:protected, true)
        @role = Role.generate!(:permissions => [:protect_wiki_pages])
        @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])

        @wiki_page.editable_by?(@user).should be_true
      end
    end
  end

  context "with redmine_advanced_wiki_permissions" do
    context "wiki page without wiki page permissions" do
      before(:each) do
        @project = Project.generate!
        @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
        @wiki = Wiki.generate!(:project => @project)
        @wiki_page = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
      end

      it "should allow user edit un-protected wiki page" do
        @wiki_page.update_attribute(:protected, false)
        @wiki_page.editable_by?(@user).should be_true
      end

      it "should not allow user edit protected wiki page" do
        @wiki_page.update_attribute(:protected, true)
        @wiki_page.editable_by?(@user).should_not be_true
      end
    end

    context "wiki page with wiki page permissions" do
      before(:each) do
        @project = Project.generate!
        @project.enabled_module_names = [:wiki, :redmine_advanced_wiki_permissions]
        @wiki = Wiki.generate!(:project => @project)
        @wiki_page = WikiPage.generate!(:wiki => @wiki)
        @user = User.generate!
      end

      it "should allow user edit wiki page if user has permissions" do
        @wpp = WikiPagePermission.create!(:principal => @user,
                                          :wiki_page => @wiki_page,
                                          :permissions => [:protect_wiki_pages])

        @wiki_page.update_attribute(:protected, true)
        @wiki_page.editable_by?(@user).should be_true
      end

      it "should not allow user edit wiki page without permissions for it" do
        @another_user = User.generate!
        @wpp = WikiPagePermission.create!(:principal => @another_user,
                                          :wiki_page => @wiki_page,
                                          :permissions => [:protect_wiki_pages])

        @wiki_page.update_attribute(:protected, true)
        @wiki_page.editable_by?(@user).should_not be_true
      end
    end
  end
end

