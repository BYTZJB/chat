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

%% API
-export([do_this_once/0, get_group_keys/0, add_new_client/1]).

get_client_password(Client_Id) ->
	Reply = do(qlc:q([E#client.password || E <- mnesia:table(client)])).


do_this_once() ->
	mnesia:create_schema([node()]),
	mnesia:start(),
	mnesia:create_table(client, [{attributes, record_info(fields, client)}]),
	mnesia:create_table(group, [{attributes, record_info(fields, group)}]),
	mnesia:create_table(ids, [{attributes, record_info(fields, ids)}]),
	mnesia:stop().

add_new_client(#client{} = Client) ->
	F =
		fun() ->
			mnesia:write(Client)
		end,
	mnesia:transaction(F).

get_group_keys() ->
	do(qlc:q([E#group.id || E <- mnesia:table(group)])).

do(Q) ->
	F = fun() -> qlc:e(Q) end,
	{atomic, Val} = mnesia:transaction(F),
	Val.

