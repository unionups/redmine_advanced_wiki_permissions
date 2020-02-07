require File.dirname(__FILE__) + '/../test_helper'

class WikiPagePermissionTest < ActiveSupport::TestCase
  should_belong_to :principal
  should_belong_to :wiki_page

  should_validate_presence_of :principal
  should_validate_presence_of :wiki_page
  should_validate_presence_of :permissions

  should "return empty array on new WikiPagePermission#permissions" do
    @wpp = WikiPagePermission.new

    assert_equal [], @wpp.permissions
  end

  should "be array" do
    assert_equal Array, WikiPagePermission.new.permissions.class
  end

  should "return 10 permissions on WikiPagePermission::PERMS" do
    assert_equal 10, WikiPagePermission::PERMS.count
  end

  should "include only listed permissions" do
    assert WikiPagePermission::PERMS.include?(:view_wiki_pages)
    assert WikiPagePermission::PERMS.include?(:edit_wiki_pages)
    assert WikiPagePermission::PERMS.include?(:delete_wiki_pages)
    assert WikiPagePermission::PERMS.include?(:export_wiki_pages)
    assert WikiPagePermission::PERMS.include?(:view_wiki_edits)
    assert WikiPagePermission::PERMS.include?(:rename_wiki_pages)
    assert WikiPagePermission::PERMS.include?(:delete_wiki_pages_attachments)
    assert WikiPagePermission::PERMS.include?(:protect_wiki_pages)
    assert WikiPagePermission::PERMS.include?(:manage_wiki)
    assert !WikiPagePermission::PERMS.include?(:non_exist_perm)
  end

  context "permissions" do
    setup do
      @principal = Principal.generate!
      @wiki_page = WikiPage.generate!
    end

    should "not save WikiPagePermission object with not valid permissions" do
      @wpp = WikiPagePermission.new
      @wpp.principal = @principal
      @wpp.wiki_page = @wiki_page
      @wpp.permissions << :view_wiki_pages
      assert !@wpp.save
    end

    should "save WikiPagePermission object with valid permissions" do
      @wpp = WikiPagePermission.new
      @wpp.principal = @principal
      @wpp.wiki_page = @wiki_page
      @wpp.permissions << :broken
      assert !@wpp.save
    end
  end
end

