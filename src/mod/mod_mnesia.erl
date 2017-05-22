%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 下午4:53
%%%-------------------------------------------------------------------
-module(mod_mnesia).
-author("bytzjb").
-include("predefine.hrl").
-include_lib("stdlib/include/qlc.hrl").

%% API
-export([
	do_this_once/0,
	get_group_keys/0,
	add_client/1,
	get_client_password/1,
	query_all_data/0,
	get_friends/1,
	get_groups/1,
	get_members/1,
	get_friend_requests/1,
	get_client/1,
	update_client/2,
	init_client/0,
	init_group/0,
	add_group/1,
	get_client_name/1
	]).

get_client_password(Client_Id) ->
	do(qlc:q([E#client.password || E <- mnesia:table(client) , E#client.id == Client_Id])).

query_all_data() ->
	List = [client, group, ids],
	lists:foreach(
		fun(TableName) ->
			Reply = do(qlc:q([E || E <- mnesia:table(TableName)])),
			io:format("~p ~n", [Reply])
		end, List).

do_this_once() ->
	mnesia:start(),
	mnesia:create_table(client, [{attributes, record_info(fields, client)}]),
	mnesia:create_table(group, [{attributes, record_info(fields, group)}]),
	mnesia:create_table(ids, [{attributes, record_info(fields, ids)}]).

add_client(Client) ->
	lager:info("add client to mnesia: ~p", [Client]),
	F =
		fun() ->
			mnesia:write(Client)
		end,
	Reply = mnesia:transaction(F),
	lager:info("add new client:~p", [Reply]).

add_group(Group) ->
	lager:info("add group to mnesia: ~p", [Group]),
	F = fun() ->
		mnesia:write(Group)
			end,
	Reply = mnesia:transaction(F),
	lager:info("add new group:~p", [Reply]).

get_friends(Client_Id) ->
	[Friends] = do(qlc:q([E#client.friends || E <- mnesia:table(client), E#client.id == Client_Id])),
	Friends.

get_groups(Client_Id) ->
	do(qlc:q([E#client.groups || E <- mnesia:table(client), E#client.id == Client_Id])).

get_members(Group_Id) ->
	[Members] = do(qlc:q([E#group.members || E <- mnesia:table(group), E#group.id == Group_Id])),
	Members.

get_friend_requests(Client_Id) ->
	do(qlc:q([E#client.friend_requests || E <- mnesia:table(client), E#client.id == Client_Id])).

get_group_keys() ->
	do(qlc:q([E#group.id || E <- mnesia:table(group)])).

do(Q) ->
	F = fun() -> qlc:e(Q) end,
	{atomic, Val} = mnesia:transaction(F),
	Val.

get_client(Client_Id) ->
	[Client] = do(qlc:q([E || E <- mnesia:table(client), E#client.id == Client_Id])),
	Client.

update_client(Client, New_Client) ->
	F = fun() ->
		mnesia:delete_object(Client),
		mnesia:write(New_Client)
			end,
	Reply = mnesia:transaction(F),
	lager:info("~p", [Reply]).

init_client() ->
	Client_01 = #client{id = 1, username = "zst", password="iyw" , groups=[1], friends = [2], friend_requests = []},
	Client_02 = #client{id = 2, username = "yw", password="ist", groups=[1], friends = [1], friend_requests = []},
	mod_mnesia:add_client(Client_01),
	mod_mnesia:add_client(Client_02).


init_group() ->
	Group_01 = #group{id =1 , members = [1, 2]},
	mod_mnesia:add_group(Group_01).

get_client_name(Client_Id) ->
	lager:info("**************************"),
	[Client_Name] = do(qlc:q([E#client.username || E <- mnesia:table(client), E#client.id == Client_Id])),
	lager:info("~p ~p", [Client_Id, Client_Name]),
	Client_Name.
