%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. июль 2022 20:10
%%%-------------------------------------------------------------------
-author("aleksandr_work").

-record(config,{db_domain,
				db_user,
				db_pass,
				db,
				db_port,
				port,
				acceptors_quantity}).