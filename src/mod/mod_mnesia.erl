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
	add_new_client/1,
	get_client_password/1,
	query_all_data/0,
	get_friends/1,
	get_groups/1,
	get_members/1
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

add_new_client(Client) ->
	lager:info("~p", [Client]),
	F =
		fun() ->
			mnesia:write(Client)
		end,
	Reply = mnesia:transaction(F),
	lager:info("add new client:~p", [Reply]).

get_friends(Client_Id) ->
	do(qlc:q([E#client.friends || E <- mnesia:table(client), E#client.id == Client_Id])).

get_groups(Client_Id) ->
	do(qlc:q([E#client.groups || E <- mnesia:table(client), E#client.id == Client_Id])).

get_members(Group_Id) ->
	do(qlc:q([E#group.members || E <- mnesia:table(group), E#group.id == Group_Id])).

get_group_keys() ->
	do(qlc:q([E#group.id || E <- mnesia:table(group)])).

do(Q) ->
	F = fun() -> qlc:e(Q) end,
	{atomic, Val} = mnesia:transaction(F),
	Val.

	