%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 下午3:40
%%%-------------------------------------------------------------------
-author("bytzjb").
%%%===========================
%%% Database tables
%%%===========================
%% cmd {1 -> register, 2 -> login, 3 -> chat_with_somebody}
%% to_type {1 -> client, 2 -> group}
%% {cmd => 1, username, password}
%% {cmd => 2, id, password}
%% {cmd => 3, id, username, to_type, to_id, data}
-record(message, {cmd, id, username, password, to_type, to_id, data}).
-record(client, {id, username, password, friends, groups}).
-record(group, {id, members}).
-record(ids, {id_type, ids}).

%%%============================
%%% Ets tables
%%%============================
-record(client_pid, {id, pid}).
-record(group_pid, {id, pid}).

%%============================
%% Chat Message
%%============================
-record(tcp_agent_receive_chat,{data}).
-record(client_receive_chat, {id, data}).
-record(client_send_chat, {data}). %% 由client发送消息出去
-record(group_receive_chat, {id, data}).
-record(chat, {id, to_type, to_id, data}).
