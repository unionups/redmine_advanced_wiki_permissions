module RedmineAdvancedWikiPermissions
  module Patches
    module UpgradeApplicationHelperPatch

      def observe_field(field_id, options = {})
        # js = "$('##{field_id}').observe_field(#{options[:frequency]}, function(){
        #         let tempUrl='#{url_for options[:url].merge!(only_path: false)}';
        #         let url = new URL(tempUrl);
                
        #         url.searchParams.set('#{options[:with]}', $( this ).val()); 
        #         $.ajax({
        #         url: url.href,
        #         beforeSend: () => {
        #             #{options[:before]};
        #           }
        #         })
        #         .done( ( html ) => {
        #           #{options[:complete]};
        #           $('##{options[:update]}').html(html);
        #         });
        #       });"
        js = "$('##{field_id}').observe_field(#{options[:frequency]}, function(){
                let tempUrl='#{url_for options[:url].merge!(only_path: false)}';
                let url = new URL(tempUrl);
                url.searchParams.set('#{options[:with]}', $( this ).val()); 
             
                let target = url.pathname + url.search;
                Rails.ajax({
                  url: target,
                  type: 'get',
                  data: '',
                  success: function( response ) {
                    $('##{options[:update]}').html(response.body);
                  }
                });
              });"
        javascript_tag(js)
      end

      def remote_form_for(as_sym, obj , options = {}, &block)
        options[:name] = "form_" << as_sym.to_s unless options[:name]
        js = "$(\"form[name=#{options[:name]}]\")
                .bind('ajax:beforeSend', function(xhr, data, status) {
                    #{options[:loading] if options[:loading]}
                  })
                .bind('ajax:complete', function(xhr, data, status) {
                    #{options[:complete] if options[:complete]}
                  });"
        options.merge! as: as_sym, remote: true
        html = form_for((obj || as_sym), options, &block)
        html << javascript_tag(js)
      end
    
      def  link_to_remote( name, options = {}, html_options = {})
        options.merge! remote: true
        options.merge! html_options
        link_to name, options[:url], options.except!(:url)
      end

      def  link_to_function( name, js_str, options = {})
        options.merge! click: js_str
        link_to name, "javascript:void(0);", *options
      end
    end

    module UpgradeWatchersHelperPatch
      def watcher_tag(object, user, options={})
        watcher_link(object, user)
      end    
    end
  end
end

ApplicationHelper.send :include, RedmineAdvancedWikiPermissions::Patches::UpgradeApplicationHelperPatch
WatchersHelper.send :include, RedmineAdvancedWikiPermissions::Patches::UpgradeWatchersHelperPatch