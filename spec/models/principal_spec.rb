require File.dirname(__FILE__) + '/../spec_helper'

describe Principal do
  it { should have_many :wiki_page_permissions }
end

