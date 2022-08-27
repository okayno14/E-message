-module(app_SUITE).

-compile(export_all).

all()->
	[foo].


init_per_suite(Config)->
	Path = ct:get_config(server_conf_path),
	e_message:start(Path),
	Config.
	

end_per_suite(Config)->
	e_message ! {stop,self()},
	ok.

groups()->
	[
		{users,[sequence],[foo]}
	].

foo(_)->
	file:get_cwd().
