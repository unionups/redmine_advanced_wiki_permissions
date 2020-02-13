class WikiPagePermission < ActiveRecord::Base
  unloadable

  belongs_to :principal
  belongs_to :wiki_page
  belongs_to :delegate_permission
  serialize :permissions, Array
  serialize :bans, Array

  validates_presence_of :principal
  validates_presence_of :wiki_page

  validate :validate_permissions

  before_save :sort_permissions,
              :sort_bans
  after_create :subscribe_principals,
               :send_mail

  PERMS = [:view_wiki_pages, :edit_wiki_pages, :delete_wiki_pages,
           :export_wiki_pages, :view_wiki_edits, :rename_wiki_pages,
           :delete_wiki_pages_attachments, :protect_wiki_pages,
           :manage_wiki, :delegate_permissions]

  def permissions
    read_attribute(:permissions) || []
  end

  def bans
    read_attribute(:bans) || []
  end

  def validate_permissions
    permissions.each do |permission|
      errors.add(:permissions, "invalid permission") unless WikiPagePermission::PERMS.include?(permission)
    end
  end

  def self.exist?(principal, wiki_page)
    wiki_page.permissions.find_all{|wpp| wpp.principal_id == principal.id}.any?
  end

  def actual_for?(user)
    self.delegate_permission.nil? || !self.delegate_permission.banned.include?(user.id)
  end

  def has_permission?(action)
    return true if self.permissions.include?(action)
    false
  end

  def has_ban?(action)
    return true if self.bans.include?(action)
    false
  end

  def sort_permissions
    self.permissions = WikiPagePermission::PERMS & self.permissions
  end

  def sort_bans
    self.bans = WikiPagePermission::PERMS & self.bans
  end

  def subscribe_principals
    return false if self.permissions.empty?
    if self.principal.class.to_s == 'User'
      subscribe(self.principal)
    elsif self.principal.class.to_s == 'Group'
      self.principal.users.each do |user|
        subscribe(user)
      end
    end
  end

  def subscribe(user)
    self.wiki_page.set_watcher(user, true) if user.active?
  end

  def send_mail
    return false if self.permissions.empty?
    recipients = mail_recipients
    while recipients.any?
      Mailer.deliver_wiki_permissions_added(self.wiki_page.content, recipients.shift(100))
    end
  end

  def mail_recipients
    return [self.principal.mail] if self.principal.class.to_s == 'User' && self.principal.active?
    return group_mail_recipients if self.principal.class.to_s == 'Group'
    []
  end

  def group_mail_recipients
    mails = []
    self.principal.users.each do |user|
      mails << user.mail if user.active? && actual_for?(user) && user.mail
    end
    mails
  end
end

