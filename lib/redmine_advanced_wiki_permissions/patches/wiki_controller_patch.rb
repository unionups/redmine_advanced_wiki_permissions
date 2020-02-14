module RedmineAdvancedWikiPermissions
  module Patches
    module WikiControllerPrependPatch
        def show
          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions')
            if @page.new_record?
              if User.current.allowed_to?(:edit_wiki_pages, @project) && editable?
                edit
                render :action => 'edit'
              else
                render_404
              end
              return
            end
            unless User.current.wiki_allowed_to?(@page, :view_wiki_pages)
              return deny_access
            end
            if params[:version] && !User.current.wiki_allowed_to?(@page, :view_wiki_edits)
              # Redirects user to the current version if he's not allowed to view previous versions
              redirect_to :version => nil
              return
            end
            @content = @page.content_for_version(params[:version])
            if User.current.wiki_allowed_to?(@page, :export_wiki_pages)
              if params[:format] == 'pdf'
                send_data(wiki_page_to_pdf(@page, @project), :type => 'application/pdf', :filename => "#{@page.title}.pdf")
                return
              elsif params[:format] == 'html'
                export = render_to_string :action => 'export', :layout => false
                send_data(export, :type => 'text/html', :filename => "#{@page.title}.html")
                return
              elsif params[:format] == 'txt'
                send_data(@content.text, :type => 'text/plain', :filename => "#{@page.title}.txt")
                return
              end
            end
            @editable = editable?
            @sections_editable = @editable && User.current.wiki_allowed_to?(@page.project, :edit_wiki_pages) &&
              @content.current_version? &&
              Redmine::WikiFormatting.supports_section_edit?

            render :action => 'show'
          else
            super
          end
        end

        # edit an existing page or a new one
        def edit
          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions')
            return render_403 unless editable?
            deny_access unless User.current.wiki_allowed_to?(@page, :edit_wiki_pages)
            if @page.new_record?
              @page.content = WikiContent.new(:page => @page)
              if params[:parent].present?
                @page.parent = @page.wiki.find_page(params[:parent].to_s)
              end
            end

            @content = @page.content_for_version(params[:version])
            @content.text = initial_page_content(@page) if @content.text.blank?
            # don't keep previous comment
            @content.comments = nil

            # To prevent StaleObjectError exception when reverting to a previous version
            @content.version = @page.content.version
      
            @text = @content.text
            if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
              @section = params[:section].to_i
              @text, @section_hash = Redmine::WikiFormatting.formatter.new(@text).get_section(@section)
              render_404 if @text.blank?
            end
          else
            super
          end
        end

        def update
        
          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions')
             @page = @wiki.find_or_new_page(params[:id])
            return render_403 unless editable?
            if User.current.wiki_allowed_to?(@page, :edit_wiki_pages)
              begin
                @page.content = WikiContent.new(:page => @page) if @page.new_record?
                @page.safe_attributes = params[:wiki_page]

                @content = @page.content_for_version(params[:version])
                @content.text = initial_page_content(@page) if @content.text.blank?
                # don't keep previous comment
                @content.comments = nil

                if !@page.new_record? && params[:content].present? && @content.text == params[:content][:text]
                  attachments = Attachment.attach_files(@page, params[:attachments])
                  render_attachment_warning_if_needed(@page)
                  call_hook(:controller_wiki_edit_after_save, { :params => params, :page => @page})
                  # don't save content if text wasn't changed
                  @page.save
                  redirect_to :action => 'show', :project_id => @project, :id => @page.title
                  return
                end

                @content.comments = params[:content][:comments]
                @text = params[:content][:text]
                if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
                  @section = params[:section].to_i
                  @section_hash = params[:section_hash]
                  @content.text = Redmine::WikiFormatting.formatter.new(@content.text).update_section(params[:section].to_i, @text, @section_hash)
                else
                  @content.version = params[:content][:version]
                  @content.text = @text
                end
                @content.author = User.current
                @page.content = @content
                if @page.save
                  attachments = Attachment.attach_files(@page, params[:attachments])
                  render_attachment_warning_if_needed(@page)
                  call_hook(:controller_wiki_edit_after_save, { :params => params, :page => @page})
                  redirect_to :action => 'show', :project_id => @project, :id => @page.title
                else
                  render :action => 'edit'
                end

              rescue ActiveRecord::StaleObjectError, Redmine::WikiFormatting::StaleSectionError
                # Optimistic locking exception
                flash.now[:error] = l(:notice_locking_conflict)
                render :action => 'edit'
              end
            else
              deny_access
            end
          else
            super
          end
        end

        # rename a page
        def rename
          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions')
            if User.current.wiki_allowed_to?(@page, :rename_wiki_pages)
              return render_403 unless editable?
              @page.redirect_existing_links = true
              # used to display the *original* title if some AR validation errors occur
              @original_title = @page.pretty_title

              @page.safe_attributes = params[:wiki_page]
              if request.post? && @page.save
                flash[:notice] = l(:notice_successful_update)
                redirect_to :action => 'show', :project_id => @project, :id => @page.title
              end
            else
              deny_access
            end
          else
            super
          end
        end

        def protect
          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions')
            if User.current.wiki_allowed_to?(@page, :protect_wiki_pages)
              protect_without_wiki_permissions
            else
              deny_access
            end
          else
            super
          end
        end

        # show page history
        def history
          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions')
            if User.current.wiki_allowed_to?(@page, :view_wiki_edits)
              history_without_wiki_permissions
            else
              deny_access
            end
          else
            super
          end
        end

        # Removes a wiki page and its history
        # Children can be either set as root pages, removed or reassigned to another parent page
        def destroy
          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions')
            return render_403 unless editable?
            if User.current.wiki_allowed_to?(@page, :delete_wiki_pages)
              @descendants_count = @page.descendants.size
              if @descendants_count > 0
                case params[:todo]
                when 'nullify'
                  # Nothing to do
                when 'destroy'
                  # Removes all its descendants
                  @page.descendants.each(&:destroy)
                when 'reassign'
                  # Reassign children to another parent page
                  reassign_to = @wiki.pages.find_by_id(params[:reassign_to_id].to_i)
                  return unless reassign_to
                  @page.children.each do |child|
                    child.update_attribute(:parent, reassign_to)
                  end
                else
                  @reassignable_to = @wiki.pages - @page.self_and_descendants
                  return
                end
              end
              @page.destroy
              redirect_to :action => 'index', :project_id => @project
            else
              deny_access
            end
          else
            super
          end
        end

        # Export wiki to a single pdf or html file
        def export
          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions')
            @pages = @wiki.pages.all(:order => 'title', :include => [:content, :attachments], :limit => 75)
            respond_to do |format|
              format.html {
                export = render_to_string :action => 'export_multiple', :layout => false
                send_data(export, :type => 'text/html', :filename => "wiki.html")
              }
              format.pdf {
                send_data(wiki_pages_to_pdf(@pages, @project), :type => 'application/pdf', :filename => "#{@project.identifier}.pdf")
              }
            end
          else
            super
          end
        end

        
        def ignore_permissions
          find_existing_page
          unless User.current.wiki_manager?(@page.project)
            return render_403
          end
          @page.update_attribute :ignore_permissions, params[:ignore_permissions]
          redirect_to :action => 'permissions', :project_id => @project, :id => @page.title
        end

      private
        def load_pages_for_index
          @pages = @wiki.pages.with_updated_on.all(:order => 'title', :include => {:wiki => :project})
          if @project.module_enabled?('redmine_advanced_wiki_permissions')
            @pages.reject!{ |page| !User.current.wiki_allowed_to?(page, :view_wiki_pages) }
          else
            super
          end
        end

    end
    module WikiControllerPatch
      extend ActiveSupport::Concern
      included do 
        helper :wiki_permissions
        include WikiPermissionsHelper

        def permissions
          find_existing_page
          unless User.current.allowed_to_manage_wiki_rights?(@page)
            return render_403
          end
          @wiki_page_permissions = @page.permissions
          @wiki_page = @page
          render :template => 'wiki_permissions/permissions'
        end
      end
    end
  end
end
WikiController.send :include, RedmineAdvancedWikiPermissions::Patches::WikiControllerPatch
WikiController.send :prepend, RedmineAdvancedWikiPermissions::Patches::WikiControllerPrependPatch
