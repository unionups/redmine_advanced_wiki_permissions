require File.expand_path('../../spec_helper', __FILE__)

describe SearchController do
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
    @role = Role.generate!(:permissions => [:view_wiki_pages])
    @member = Member.generate!(:principal => @user, :project => @project, :roles => [@role])
  end

  it "should return all wiki pages" do
    @wpp = WikiPagePermission.create!(:principal => @user,
                                      :wiki_page => @wiki_page,
                                      :permissions => [:view_wiki_pages])

    get :index, :scope => 'all', :all_words => '',
        :wiki_pages => 1, :id => @project.identifier, :q => 'Demo', :titles_only => ''

    assigns[:results].count.should == 1
    assigns[:results_by_type]['wiki_pages'].should == 1 
  end

  it "should not return all wiki pages" do
    @another_user = User.generate!
    @wpp = WikiPagePermission.create!(:principal => @another_user,
                                      :wiki_page => @wiki_page,
                                      :permissions => [:view_wiki_pages])

    get :index, :wiki_pages => 1, :id => @project, :q => 'Demo'
    assigns[:results].count.should == 0
    assigns[:results_by_type]['wiki_pages'].should == 0
  end
end

