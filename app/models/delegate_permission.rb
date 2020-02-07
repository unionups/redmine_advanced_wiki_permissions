class DelegatePermission < ActiveRecord::Base
  unloadable

  belongs_to :user
  belongs_to :project
  has_many :wiki_page_permissions
  serialize :permitted, Array
  serialize :banned, Array

  validates_presence_of :user
  validates_presence_of :project

  validate :validate_permitted
  validate :validate_banned

  def permitted
    read_attribute(:permitted) || []
  end

  def banned
    read_attribute(:banned) || []
  end

  def validate_permitted
    permitted.each do |permitt|
      errors.add(:permitted, "invalid permitted") unless Principal.all.map(&:id).include?(permitt)
    end
  end

  def validate_banned
    banned.each do |bann|
      errors.add(:banned, "invalid banned") unless Principal.all.map(&:id).include?(bann)
    end
  end

  def exist?
    DelegatePermission.all.include?(self)
  end

  def permitted_groups
    permitted.map{|permitt| Principal.find(permitt) if Principal.find(permitt).class == Group}.compact
  end

  def permitted_users
    permitted.map{|permitt| Principal.find(permitt) if Principal.find(permitt).class == User}.compact
  end

  def users_from_permitted_groups
    permitted_groups.map{|group| group.users}.flatten.uniq
  end

  def banned_users
    banned.map{|bann| User.find(bann)}
  end

  def users_for_delegate
    (permitted_users | users_from_permitted_groups - banned_users).sort
  end

  def principals_for_delegate
    permitted_groups + users_for_delegate
  end
end

