План работ:
этап первый:
  1) добавление прав на вики страницы
    а) :rename_wiki_page -- право на переименовывание вики страницы.
    б) :delete_wiki_page -- право на удаление вики страницы.
    в) :view_wiki_page -- право на просмотр вики страницы.
    г) :export_wiki_page -- право на экспорт вики страницы.
    д) :view_wiki_edits -- право смотреть историю правок.
    и) :edit_wiki_page -- право редактировать вики страницу.
    ж) :delete_wiki_page_attachments -- право удалять аттачи.
    з) :protect_wiki_page -- право защищать вики страницу.
    к) :manage_rights -- право на управление правами для вики страницы.
  2) добавление нового права для пользователя :manage_wiki_rights
     которое позволяет изменять права на вики страницы в проекте
     (добавляется или удаляется на странице "роли и права")
  3) реализация в виде плагина который можно включать и выключать по проектам
  4) установленный, но не включённый плагин не должен влиять на работу вики
     (из-за особенностей реализации плагинов в redmine скорее всего миграцию
     придётся запустить)
  5) если у пользователя нет никаких записей о правах на вики страницу, то
     используются настройки проекта (согласно его ролям в проекте и правам
     в них)
  6) по поводу прав и их наследование:
     а) админ может читать, менять и делать что угодно со страницами вики.
        а так же, развадать и убирать любые права на любые страницы для всех
        пользователей всех проектов
     б) пользователь с ролью :manage_wiki_rights может менять все права на
        все вики страницы в проекте не в зависимости от прав в самой странице
     в) пользователь с правом :manage_rights может менять как угодно права
        на вики страницу для всех пользователей (это так же подразумевает
        что он может удалить у себя все права на вики страницу и больше не
        сможет менять права)
     г) если у пользователя есть право :manage_rights то остальные права
        игнорируются
     д) права плюсуются сверху в низ. т.е.
        вначале, права от проекта на вики
        потом к ним права из самой вики страницы
        (или если говорить техническим языком, то права вначале смотрятся
         в правах на вики страницу, потом в самом проекте)
  7) права на вики страницы раздаются для пользователей и групп
  8) при поиске, тоже должны учитыватся права. если пользователь не может
     видеть страницу, то показывать её на странице поиска не надо.

этап два:

