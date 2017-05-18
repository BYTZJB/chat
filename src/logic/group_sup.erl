%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 下午5:00
%%%-------------------------------------------------------------------
-module(group_sup).
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

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
	{ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
	supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%%
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
	{ok, {SupFlags :: {RestartStrategy :: supervisor:strategy(),
		MaxR :: non_neg_integer(), MaxT :: non_neg_integer()},
		[ChildSpec :: supervisor:child_spec()]
	}} |
	ignore |
	{error, Reason :: term()}).
init([]) ->
	RestartStrategy = one_for_one,
	MaxRestarts = 1000,
	MaxSecondsBetweenRestarts = 3600,
	
	SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
	
	Restart = permanent,
	Shutdown = 2000,
	Type = worker,
	
	Ids = mod_group_sup:get_all_group(),
	lager:info("~p ~n", [Ids]),
	Childes_Spec = lists:map(
		fun(Group_Id) ->
			{Group_Id, {group, start_link, [Group_Id]},
				Restart, Shutdown, Type, [group]}
		end, Ids
	),
	lager:info("~p ", [Childes_Spec]),
	
	lager:info("######## group_sup"),
	{ok, {SupFlags, Childes_Spec}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
