%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 下午12:32
%%%-------------------------------------------------------------------
-module(test_id_generator).
-author("bytzjb").

%% API
-export([test/0]).

test() ->
	id_generator:start_link(),
	Fun =
		fun(Type) ->
			lists:foreach(
				fun(_) ->
					Id = id_generator:get_new_id(Type),
					io:format("~p ", [Id]),
					Id
				end, lists:duplicate(10, ""))
		end,
	Fun(client),
	io:format("~n"),
	Fun(chat_room).
