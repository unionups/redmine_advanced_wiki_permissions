module MailerPatch
  def self.included(base)
    base.class_eval do

      # Send mails, when users get permissions on page
      def wiki_permissions_added(wiki_content, mail_recipients)
        redmine_headers 'Project' => wiki_content.project.identifier,
                        'Wiki-Page-Id' => wiki_content.page.id
        @author = wiki_content.versions.first.author
        message_id wiki_content
        recipients wiki_content.recipients
        cc(mail_recipients - recipients)
        subject "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_added, :id => wiki_content.page.pretty_title)}"
        body :wiki_content => wiki_content,
             :wiki_content_url => url_for(:controller => 'wiki', :action => 'show',
                                          :project_id => wiki_content.project,
                                          :id => wiki_content.page.title),
             :wiki_diff_url => url_for(:controller => 'wiki', :action => 'diff',
                                       :project_id => wiki_content.project, :id => wiki_content.page.title,
                                       :version => wiki_content.version)
        render_multipart('wiki_permissions_added', body)
      end

    end
  end
end
