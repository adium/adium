/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

\set ON_ERROR STOP;

create view im.meta_names as (
select meta_id, name, service, username, user_id
from im.meta_container
natural join im.meta_contact
natural join im.users
);

create or replace rule insert_meta_contact as
on insert to im.meta_names
do instead (
    insert into im.meta_container (name)
    select new.name
    where not exists (
        select  'x'
        from    im.meta_container
        where   name = new.name);

    insert into im.meta_contact (meta_id, user_id, preferred)
    select (select meta_id from im.meta_container where name = new.name),
        (select user_id from im.users
        where username = lower(new.username) and service = new.service),
        exists (select 'x' from im.meta_contact where user_id =
            (select user_id from users where username = lower(new.username)
            and service = new.service));
    );

alter table messages add column random_id float8;
update messages set random_id = random();
alter table messages alter column random_id set default random();
vacuum analyze;

alter table im.user_statistics add column period date;
alter table im.user_statistics drop column last_message;
alter table im.user_statistics drop constraint user_statistics_pkey;

truncate im.user_statistics;

insert into im.user_statistics
    (select sender_id,
            recipient_id,
            count(*),
            date_trunc('month', message_date)::date
    from    messages
    group by sender_id,
            recipient_id,
            date_trunc('month', message_date)::date);

create or replace rule insert_message_v as
on insert to im.message_v
do instead  (

    -- Usernames

    insert into im.users (username,service)
    select lower(new.sender_sn), coalesce(new.sender_service, 'AIM')
    where not exists (
        select 'x'
        from im.users
        where username = lower(new.sender_sn)
        and service ilike coalesce(new.sender_service, 'AIM'));

    insert into im.users (username, service)
    select lower(new.recipient_sn), coalesce(new.recipient_service, 'AIM')
    where not exists (
        select 'x'
        from im.users
        where username = lower(new.recipient_sn)
        and service ilike coalesce(new.recipient_service, 'AIM'));

    -- Display Names
    insert into im.user_display_name
    (user_id, display_name, effdate)
    select user_id,
        case when new.sender_display is null
        or new.sender_display = ''
        then new.sender_sn
        else new.sender_display end,
        coalesce(new.message_date, now())
    from   im.users
    where  username = lower(new.sender_sn)
     and   service ilike coalesce(new.sender_service, 'AIM')
    and not exists (
        select 'x'
        from   im.user_display_name udn
        where  user_id =
               (select user_id from im.users
                where  username = lower(new.sender_sn)
                 and   service ilike coalesce(new.sender_service, 'AIM'))
            and   display_name = case when new.sender_display is null
             or new.sender_display = '' then new.sender_sn
              else new.sender_display end
            and effdate < coalesce(new.message_date, now())
            and not exists (
                select 'x'
                from im.user_display_name
                where effdate > udn.effdate
                and effdate < coalesce(new.message_date, now())
                and user_id = udn.user_id));

    insert into im.user_display_name
    (user_id, display_name, effdate)
    select user_id,
        case when new.recipient_display is null
        or new.recipient_display = ''
        then new.recipient_sn
        else new.recipient_display end,
        coalesce(new.message_date, now())
    from im.users
    where username = lower(new.recipient_sn)
     and  service ilike coalesce(new.recipient_service, 'AIM')
     and not exists (
        select 'x'
        from   im.user_display_name udn
        where  user_id =
               (select user_id from im.users
               where username = lower(new.recipient_sn)
                and  service ilike coalesce(new.recipient_service, 'AIM'))
        and    display_name = case when new.recipient_display is null or
        new.recipient_display = '' then new.recipient_sn
         else new.recipient_display end
        and effdate < coalesce(new.message_date, now())
        and not exists (
            select 'x'
            from   im.user_display_name
            where  effdate > udn.effdate
             and   effdate < coalesce(new.message_date, now())
             and   user_id = udn.user_id));

    -- The mesage
    insert into im.messages
        (message,sender_id,recipient_id, message_date)
    values (new.message,
    (select user_id from im.users where username = lower(new.sender_sn) and
    service ilike coalesce(new.sender_service, 'AIM')),
    (select user_id from im.users where username = lower(new.recipient_sn) and
    service ilike coalesce(new.recipient_service, 'AIM')),
    coalesce(new.message_date, now() )
    );

    -- Updating statistics
    update im.user_statistics
    set num_messages = num_messages + 1
    where sender_id = (select user_id
                        from im.users
                        where username = lower(new.sender_sn)
                         and service ilike coalesce(new.sender_service, 'AIM'))
    and recipient_id = (select user_id
                        from im.users
                        where username = lower(new.recipient_sn)
                        and service ilike coalesce(new.recipient_service, 'AIM'))
    and period = date_trunc('month', coalesce(new.message_date, now()))::date;

    -- Inserting statistics if none exist
    insert into im.user_statistics
    (sender_id, recipient_id, num_messages, period)
    select
    (select user_id
        from im.users
        where username = lower(new.sender_sn)
        and service ilike new.sender_service),
    (select user_id
        from im.users
        where username = lower(new.recipient_sn)
        and service ilike new.recipient_service),
    1,
    date_trunc('month', coalesce(new.message_date, now()))::date
    where not exists
        (select 'x'
        from im.user_statistics
        where sender_id =
            (select user_id
            from im.users
            where username = lower(new.sender_sn)
            and service ilike new.sender_service)
        and recipient_id =
            (select user_id
            from im.users
            where username = lower(new.recipient_sn)
            and service ilike new.recipient_service)
        and period = date_trunc('month', coalesce(new.message_date, now()))::date)
);
