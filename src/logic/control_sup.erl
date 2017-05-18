%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 上午11:27
%%%-------------------------------------------------------------------
-module(control_sup).
-author("bytzjb").

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

start_link() ->
	supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

init([]) ->
	RestartStrategy = one_for_one,
	MaxRestarts = 1000,
	MaxSecondsBetweenRestarts = 3600,
	
	SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
	
	Restart = permanent,
	Shutdown = 2000,
	
	%% 新建各种表
	mod_control_sup:init(),
	
	Id_generator = {id_generator, {id_generator, start_link, []},
		Restart, Shutdown, worker, [id_generator]},
	
	Group_sup= {group_sup, {group_sup, start_link, []},
		Restart, Shutdown, supervisor, [group_sup]},
	
	Client_sup= {client_sup, {client_sup, start_link, []},
		Restart, Shutdown, supervisor, [client_sup]},
	
	Tcp_Agent_sup= {tcp_agent_sup, {tcp_agent_sup, start_link, []},
		Restart, Shutdown, supervisor, [tcp_agent_sup]},
	
	Acceptor = {tcp_acceptor, {tcp_acceptor, start_link, []},
		Restart, Shutdown, worker, [tcp_acceptor]},
	
	Childes_Spec = [Id_generator, Group_sup, Client_sup, Tcp_Agent_sup, Acceptor],
	
	lager:info(""),
	{ok, {SupFlags, Childes_Spec}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
