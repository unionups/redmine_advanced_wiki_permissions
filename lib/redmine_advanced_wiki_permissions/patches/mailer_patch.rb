module RedmineAdvancedWikiPermissions
  module Patches
    module MailerPatch
      extend ActiveSupport::Concern
      included do
        def wiki_permissions_added(mail, wiki_content, mail_recipients)
          redmine_headers 'Project' => wiki_content.project.identifier,
                          'Wiki-Page-Id' => wiki_content.page.id
          @author = wiki_content.author
          message_id wiki_content
        
          body :wiki_content => wiki_content,
               :wiki_content_url => url_for(:controller => 'wiki', :action => 'show',
                                            :project_id => wiki_content.project,
                                            :id => wiki_content.page.title),
               :wiki_diff_url => url_for(:controller => 'wiki', :action => 'diff',
                                         :project_id => wiki_content.project, :id => wiki_content.page.title,
                                         :version => wiki_content.version)
          
          mail( to: mail,
                cc: (mail_recipients - wiki_content.recipients),
                subject: "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_added, :id => wiki_content.page.pretty_title)}"
              )  do |format|
                format.html { render_multipart('wiki_permissions_added', body) }
                format.text { render_multipart('wiki_permissions_added', body)}
              end  

        end

      end

      class_methods do
        def deliver_wiki_permissions_added(wiki_content, mail_recipients)
          mail_recipients.each do |mail|
            wiki_permissions_added(mail, wiki_content, mail_recipients).deliver_later
          end
        end
      end  
    end
  end
end

Mailer.send :include, RedmineAdvancedWikiPermissions::Patches::MailerPatch