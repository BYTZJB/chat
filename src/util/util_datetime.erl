%% Author: Administrator
%% Created: 2012-4-13
%% Description: TODO: Add description to util_datetime
-module(util_datetime).

%%
%% Include files
%%
-include("time.hrl").
%%
%% Exported Functions
%%
-compile(export_all).
%%
%% API Functions
%%

%%获取json格式的当前时间
jsontime()->
	{Date,Time}=calendar:local_time(),
	{Year,Moth,Day}=Date,
	{Hour,Minite,Second}=Time,
	DateNum=calendar:day_of_the_week(Date),
	{obj,[
		  {"date",DateNum},
		  {"day",Day},
		  {"hours",Hour},
		  {"minutes",Minite},
		  {"month",Moth},
		  {"seconds",Second},
		  {"time",util_datetime:timestamp_hi()*1000},
		  {"timezoneOffset",-480},
		  {"year",Year-1900}
		  ]		
	}
.

recordtime()->
	{Date,Time}=calendar:local_time(),
	{Year,Moth,Day}=Date,
	{Hour,Minite,Second}=Time,
	DateNum=calendar:day_of_the_week(Date),
	#time{date=DateNum,
		  day=Day,
		  hours=Hour,
		  minutes=Minite,
		  month=Moth,
		  seconds=Second,
		  thetime=util_datetime:timestamp_hi()*1000,
		  offset=-480,
		  year=Year-1900
		 }
.

%% 将当前时间转换成通用的时间戳
timestamp() ->
    Int = timestamp_mi(),
	Bin = integer_to_list( Int ),
	list_to_binary( dsort( Bin ) ).
dsort( Str ) -> 
	lists:concat( [ $9 - I || I <- Str ] ).
%% 将当前时间转换成通用的时间戳到微秒 
timestamp_mi() ->
	{Mega, Seconds, Milli} = erlang:now(),
	Mega * 1000000 * 1000000 + Seconds * 1000000 + Milli.
%
hex_l( N ) when N < 10 -> lists:concat( ["0", N] );
hex_l( N ) -> integer_to_list( N ).
%% 将当前时间转换成通用的时间戳到毫秒 
timestamp_hi() ->
	{Mega, Seconds, _Milli} = erlang:now(),
	Mega * 1000000  + Seconds .	

%%标准时间戳转日期
timestamp_to_date(Time)  ->
    DigitTime =
        if is_binary(Time) -> list_to_integer(binary_to_list(Time));
            is_list(Time) ->  list_to_integer(Time);
            true -> Time
        end,
    if DigitTime =:= 0   ->
            Nlocal = calendar:local_time(),
            Ntime  = calendar:datetime_to_gregorian_seconds(Nlocal);
        true    ->
            Dlocal= calendar:universal_time_to_local_time({{1970, 1, 1},{0,0,0}}),
            D1970 = calendar:datetime_to_gregorian_seconds(Dlocal),
            Ntime = D1970 + DigitTime
    end,
    {{Y2,M2,D2},{H2,I2,S2}} = calendar:gregorian_seconds_to_datetime(Ntime),
    {{Y2,M2,D2},{H2,I2,S2}}.
timestamp_to_date(Time, Type) -> 
    {{Y2,M2,D2},{H2,I2,S2}} = timestamp_to_date(Time),
    date_to_binary({{Y2,M2,D2},{H2,I2,S2}}, Type).

date_to_binary() ->
    date_to_binary(erlang:localtime(),0).
date_to_binary(Localtime) ->
    date_to_binary(Localtime,0).
date_to_binary(Localtime, Type) ->
    {{Y2,M2,D2},{H2,I2,S2}} = Localtime,
    {{Y, M, D}, {H, I, S}}  = {{date_format(Y2),date_format(M2),date_format(D2)},{date_format(H2),date_format(I2),date_format(S2)}},
    case Type of
        1   ->
            Date = Y++"年"++M++"月"++D++"日 "++H++"时"++I++"分"++S++"秒";
        2   ->
            Date = Y++"年"++M++"月"++D++"日";%%yyyy年MM月dd日
        3   ->
            Date = Y++"-"++M++"-"++D;%%yyyy-MM-dd
        4   ->
            Date = Y++M++D;%%yyyyMMdd
        5   ->
            Date = Y++M++D++H++I++S;%%yyyyMMddHHmmss
        _   ->
            Date = Y++"-"++M++"-"++D++" "++H++":"++I++":"++S%%yyyy-MM-dd HH:mm:ss
    end,
    list_to_binary(Date).

date_format(M)   ->
    if M < 10   ->
            N = "0" ++ integer_to_list(M);
        true ->
            N = integer_to_list(M)
    end,
    N.

%%下一天
next_day(Date) ->
    {Y,M,D} = Date,
    Date1 = calendar:date_to_gregorian_days(Y,M,D),
    calendar:gregorian_days_to_date(Date1 + 1).

%%上一天
pre_day(Date) ->
    {Y,M,D} = Date,
    Date1 = calendar:date_to_gregorian_days(Y,M,D),
    calendar:gregorian_days_to_date(Date1-1).
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% week_of_the_year(Date) -> {Year, Week}
%%
%% Date   = {Year, Month, Day}
%% Year  = int()
%% Month = 1..12
%% Day   = 1..31
%% Week  = 1..53
%%
%% This function computes the week number of a given day
%% according to the ISO8601 standard.
%%
%% In ISO8601 the week number is defined by these rules:
%% - weeks start on a monday
%% - week 1 of a given year is the one that includes the
%%   4th of January. Or, equivalently, week 1 is the week
%%   that includes the first  Thursday of that year.
%% 
%% Normally the returned Year is the same as the given Year,
%% but the first and last days of a year can actually
%% belong to the previous respective next year. For example,
%% the day {2012, 1, 1} is included in week 52 in 2011 and
%% the day {2012, 12, 31} is included in week 1 in 2012.
%% The day {2009, 12, 28} is included in week 53 in 2009.
%%
%% The ISO860 standard is used by most European countries.
%% There are also several other week numbering systems that
%% are used in various parts of the world. Some have monday
%% the first day of the week while others have wednesday,
%% saturday or sunday. Some defines the first week of the
%% year as the week containing the 1st of january, while
%% others uses the 4th or 7th.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

week_of_the_year({Year, _Month, _Day} = Date) ->
    MondayInFirstWeek = monday_of_the_first_week(Year),
    ActualDay = calendar:date_to_gregorian_days(Date),
    Diff = ActualDay - MondayInFirstWeek,
    Week = (Diff div 7) + 1,
    if
        Diff < 0 ->
            %% The day belongs to the last week of the previous year
            week_of_the_year({Year - 1, 12, 31});
        Week > 52 ->
            MondayInFirstWeek2 = monday_of_the_first_week(Year + 1),
            if
                ActualDay >= MondayInFirstWeek2 ->
                    {Year + 1, 1};
                true ->
                    {Year, Week}
            end;
        true ->
            {Year, Week}
    end.

monday_of_the_first_week(Year) ->
    PivotDate = {Year, 1, 4},
    PivotDay = calendar:date_to_gregorian_days(PivotDate),
    PivotDay + 1 - calendar:day_of_the_week(PivotDate).

monday_of_the_week({Year, Week}) when is_integer(Year), is_integer(Week) ->
    MondayInFirstWeek = monday_of_the_first_week(Year),
    calendar:gregorian_days_to_date((MondayInFirstWeek + ((Week - 1) * 7))).

last_week_no_of_the_year(YearNo) ->
    case week_of_the_year({YearNo, 12, 31}) of
        {Y, WeekNo} when Y =:= YearNo ->
            WeekNo;
        {_, _} ->
            {_, WeekNo} = week_of_the_year({YearNo, 12, 31 - 7}),
            WeekNo
    end.




%%
%% Local Functions
%%

