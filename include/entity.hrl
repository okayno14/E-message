%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 15:47
%%%-------------------------------------------------------------------
-author("aleksandr_work").
-record(user,{nick="",
        pass="123qwerty"}).
-record(dialogue,{id=-1,
                  name="",
                  users=[],
                  messages=[]}).
%%-enum(message_state,{written, sent, read}).
-record(message,{id=-1,
                from="",
                timeSending=0,
                text="",
                state=written,
                artifactID=[]}).
%%-enum(mime,{audio,image,video,application_zip}).
-record(artifact,{id=-1,
                  mime="",
                  path=""}).
-record(seq,{table_name="",
            counter=0}).