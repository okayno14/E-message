-module(app_SUITE).

-compile(export_all).

-include_lib("e_message/include/entity.hrl").
-include_lib("jsonerl/include/jsonerl.hrl").

all()->
	[{group,users}].


init_per_suite(Config)->
	Path = ct:get_config(server_conf_path),
	e_message:start(Path),
	Config.
	

end_per_suite(Config)->
	e_message ! {stop,self()},
	ok.

groups()->
	[
		{users,[sequence],[get_dialogues1,get_dialogues2]}
	].

%user exists
%valid data
get_dialogues1(_)->
	Nick=ct:get_config(user1_nick),
	Pass=ct:get_config(user1_pass),
	client:get_dialogues(#user{nick=Nick, pass=Pass}).

%invalid nick
get_dialogues2(_)->
	Buf=binary_to_list(ct:get_config(user1_nick)),
	Nick = list_to_binary(["abrrakadabra "|Buf]),
	Pass=ct:get_config(user1_pass),
	client:get_dialogues(#user{nick=Nick, pass=Pass}).