%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 上午11:33
%%%-------------------------------------------------------------------
-module(client).
-author("bytzjb").

-behaviour(gen_server).
-include("predefine.hrl").

%% API
-export([
	start_link/0
]).

%% gen_server callbacks
-export([init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {tcp_agent_pid, client_id , client_socket}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
	{ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
	gen_server:start_link(?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
	{ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
	{stop, Reason :: term()} | ignore).
init([]) ->
	lager:info("success to create a client"),
	{ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
	State :: #state{}) ->
	{reply, Reply :: term(), NewState :: #state{}} |
	{reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
	{noreply, NewState :: #state{}} |
	{noreply, NewState :: #state{}, timeout() | hibernate} |
	{stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
	{stop, Reason :: term(), NewState :: #state{}}).
handle_call(_Request, _From, State) ->
	{reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
	{noreply, NewState :: #state{}} |
	{noreply, NewState :: #state{}, timeout() | hibernate} |
	{stop, Reason :: term(), NewState :: #state{}}).
handle_cast(online, State) ->
	{noreply, State};

%% 用于处理用户获得tcp_agent_pid,client_id
handle_cast({get_state, #{tcp_agent_pid := Tcp_Agent_Pid, client_id := Client_Id, client_socket := Socket}}, State) ->
	lager:info("client state: tcp_agent_pid ~p, client_id ~p, client_socket ~p", [Tcp_Agent_Pid, Client_Id, Socket]),
	{noreply, State#state{tcp_agent_pid = Tcp_Agent_Pid, client_id = Client_Id, client_socket = Socket}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
	{noreply, NewState :: #state{}} |
	{noreply, NewState :: #state{}, timeout() | hibernate} |
	{stop, Reason :: term(), NewState :: #state{}}).
%%  给群组或者客户端发送聊天信息
handle_info(#client_send_chat{data = Chat}, State) ->
	lager:info("send message to other client"),
	#chat{id = Id, to_type = To_Type, to_id = To_Id, data = Data} = Chat,
	{To_Pid, To_Chat} =
		case To_Type of
			1 ->
				[{_, Res}] = ets:lookup(client_pid, To_Id),
				{Res, #client_receive_chat{id = Id, data = Data}};
			2 ->
				[{_, Res}] = ets:lookup(group_pid, To_Id),
				{Res, #group_receive_chat{id = Id, data = Data}};
			_ ->
				error
		end,
	lager:info("~p", [To_Pid]),
	lager:info("~p", [To_Chat]),
	To_Pid ! To_Chat,
	{noreply, State};

%% 接收别人传过来的消息,并发送给客户端
handle_info(#client_receive_chat{id = Id, data = Data} , #state{client_socket = Socket} = State) ->
	lager:info("receive message and send to socket"),
	Message = "\n" ++ integer_to_list(Id) ++ " said: \n" ++ Data,
	lager:info("~p", [Socket]),
	lager:info("~p", [Message]),
	gen_tcp:send(Socket, Message),
	{noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
	State :: #state{}) -> term()).
terminate(_Reason, _State) ->
	ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
	Extra :: term()) ->
	{ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
