module ProjectPatch
  def self.included(base)
    base.class_eval do
      has_many :delegate_permissions, :dependent => :destroy
    end
  end
end
