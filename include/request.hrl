%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 15:49
%%%-------------------------------------------------------------------
-author("aleksandr_work").
-record(hello,{x=1,y=1}).

-record(create_user,{nick,pass}).

-record(create_dialogue,{nick,pass,name,userNicks}).
-record(get_dialogues,{nick,pass}).
-record(quit_dialogue,{nick,pass,id}).

-record(send_message,{nick,pass,text,artifactID}).
-record(get_messages,{nick,pass,id}).
-record(read_message,{nick,pass,id}).
-record(edit_message,{nick,pass,id,text,artifactID}).
-record(delete_message,{nick,pass,id}).

-record(create_artifact,{mime,fileName}).
-record(get_artifact,{id}).