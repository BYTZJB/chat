%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 上午11:35
%%%-------------------------------------------------------------------
-module(tcp_acceptor).
-author("bytzjb").
-include("network.hrl").

%% API
-export([start/0, accept_loop/1]).

start() ->
	lager:info("######## tcp_acceptor"),
	Port = ?Listen_Port,
	case (do_init(Port)) of
		{ok, ListenSocket} ->
			accept_loop(ListenSocket);
		_Els ->
			error
	end.

do_init(Port) when is_integer(Port) ->
	Options = [binary,
		{packet, 0},
		{reuseaddr, true},
		{backlog, 1024},
		{active, true}],
	case gen_tcp:listen(Port, Options) of
		{ok, ListenSocket} ->
			{ok, ListenSocket};
		{error, Reason} ->
			{error, Reason}
	end.

accept_loop(ListenSocket) ->
	case (gen_tcp:accept(ListenSocket, 3000)) of
		{ok, Socket} ->
			process_clientSocket(Socket),
			?MODULE:accept_loop(ListenSocket);
		{error, _Reason} ->
			?MODULE:accept_loop(ListenSocket);
		{exit, _Reason} ->
			?MODULE:accept_loop(ListenSocket)
	end.

process_clientSocket(Socket) ->
	lager:info(""),
	{ok, Tcp_Agent} = tcp_agent_sup:start_child(),
	ok = gen_tcp:controlling_process(Socket, Tcp_Agent),
	gen_fsm:send_event(Tcp_Agent, {go, Socket}),
	lager:info(""),
%%	Record = chat_room:getPid(),
%%	chat_room:bindPid(Record, Socket),
	ok.

