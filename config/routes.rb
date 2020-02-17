RedmineApp::Application.routes.draw do

  resources :projects do

    resources :delegate_permissions do
      collection do
        match "/create", to: 'delegate_permissions#create', via: [:post, :put, :patch]
        match "/:id/update", to: 'delegate_permissions#update', via: [:post, :put, :patch]
        get "/change_user_edit", to: "delegate_permissions#change_user_edit", as: :change_user_edit
        match "/change_user_update", to: "delegate_permissions#change_user_update", as: :change_user_update, via: [:post, :put, :patch]
        match "/autocomplete_for_new_dp", to: 'delegate_permissions#autocomplete_for_new_dp', via: :all
        match "/autocomplete_for_permitted", to: 'delegate_permissions#autocomplete_for_permitted', via: :all
        match "/autocomplete_for_banned", to: 'delegate_permissions#autocomplete_for_banned', via: :all
        match "/autocomplete_for_user_change", to: 'delegate_permissions#autocomplete_for_user_change', via: :all
        delete "/destroy_following_wpps", to: "delegate_permissions#destroy_following_wpps", as: :destroy_following_wpps
        match "/update_following_wpps", to: "delegate_permissions#update_following_wpps", as: :update_following_wpps, via: [:post, :put, :patch]
        delete "/:id/destroy_permitted", to: "delegate_permissions#destroy_permitted", as: :destroy_permitted
        delete "/:id/destroy_banned", to: "delegate_permissions#destroy_banned", as: :destroy_banned
      end
    end

    resources :wiki  do
      collection do
        get "/:id/permissions", to: 'wiki#permissions'
      end
    end
  end
  resource :permissions, path: "projects/:project_id/wiki/:id/permissions", controller: 'wiki_permissions' do
    get "/autocomplete_for_member", to: 'wiki_permissions#autocomplete_for_member'
    match "/ignore_permissions", to: 'wiki#ignore_permissions', via: [:post, :put, :patch]
    get "/ignore_permissions", to: 'wiki#show'
    match "/update_following_wpps", to: 'wiki_permissions#update_following_wpps',
                                    via: :all,
                                    as: :update_following_wpps
    match "/destroy_following_wpps", to: 'wiki_permissions#destroy_following_wpps',
                                     via: :all,
                                     as: :destroy_following_wpps
    match "/update_page", to: 'wiki_permissions#update_page',
                                    via: :all,
                                    as: :update_page
    delete "/destroy", to: 'wiki_permissions#destroy', as: :destroy
  end  
end
