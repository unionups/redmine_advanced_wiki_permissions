require File.dirname(__FILE__) + '/../spec_helper'

describe WikiPagePermission do
  it { should belong_to :principal }
  it { should belong_to :wiki_page }

  it { should validate_presence_of :principal }
  it { should validate_presence_of :wiki_page }

  it "should be array" do
    WikiPagePermission.new.permissions.should be_a_kind_of(Array)
  end

  it "should return [] on WikiPagePermission#permissions" do
    WikiPagePermission.new.permissions.should == []
  end

  it "should return 10 permissions on WikiPagePermission::PERMS" do
    WikiPagePermission::PERMS.count.should be 10
  end

  it "should include only listed permissions" do
    WikiPagePermission::PERMS.should include :view_wiki_pages
    WikiPagePermission::PERMS.should include :edit_wiki_pages
    WikiPagePermission::PERMS.should include :delete_wiki_pages
    WikiPagePermission::PERMS.should include :export_wiki_pages
    WikiPagePermission::PERMS.should include :view_wiki_edits
    WikiPagePermission::PERMS.should include :rename_wiki_pages
    WikiPagePermission::PERMS.should include :delete_wiki_pages_attachments
    WikiPagePermission::PERMS.should include :protect_wiki_pages
    WikiPagePermission::PERMS.should include :manage_wiki
    WikiPagePermission::PERMS.should include :manage_wiki_rights
    WikiPagePermission::PERMS.should_not include :non_exist_perm
  end

  context "permissions" do
    before(:each) do
      @principal = Principal.generate!
      @wiki_page = WikiPage.generate!
    end

    it "should save WikiPagePermission object with valid permissions" do
      @wpp = WikiPagePermission.new
      @wpp.principal = @principal
      @wpp.wiki_page = @wiki_page
      @wpp.permissions = [:view_wiki_pages]
      @wpp.save.should be_true
    end

    it "should not save WikiPagePermission object with invalid permissions" do
      @wpp = WikiPagePermission.new
      @wpp.principal = @principal
      @wpp.wiki_page = @wiki_page
      @wpp.permissions = [:broken]
      @wpp.save.should_not be_true
    end
  end

  context "#delegate_list" do
    before(:each) do
      @user = User.generate!
      @wiki_page = WikiPage.generate!
    end

    it "should return list of delegated rights" do
      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => WikiPagePermission::PERMS)

      WikiPagePermission.delegate_list(@user, @wiki_page).should == WikiPagePermission::PERMS
    end

    it "should return :view_wiki_pages and :manage_wiki_rights" do
      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => [:view_wiki_pages,
                                                         :manage_wiki_rights])

      WikiPagePermission.delegate_list(@user, @wiki_page).should == [:view_wiki_pages, :manage_wiki_rights]
    end

    it "should return empty list of delegated rights" do
      @wpp = WikiPagePermission.create!(:principal => @user,
                                        :wiki_page => @wiki_page,
                                        :permissions => [:view_wiki_pages])

      WikiPagePermission.delegate_list(@user, @wiki_page).should == []
    end
  end
end

