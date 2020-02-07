require File.dirname(__FILE__) + '/../test_helper'

class PrincipalTest < ActiveSupport::TestCase
  should_have_many :wiki_page_permissions
end

