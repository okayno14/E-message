%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. июль 2022 16:16
%%%-------------------------------------------------------------------
-module(parse).


%% API
-export([encodeRecordArray/2]).

%%Конвертирует массив Erlang-записей в JSON-массив объектов
%%Data - массив записей
%%Encode - callback-функция, конвертирующая каждую запись из списка
%%Encode(type:atom, Rec), где: type - имя записи, Rec - запись
encodeRecordArray(Data,Encode)->
  JSON_List=encodeRecordArray(Data,[],Encode),
  ["{\"arr\":[" | [JSON_List|"]}"]].

encodeRecordArray([H],Res,Encode)->
  JSON=Encode(H),
  lists:reverse([JSON|Res]);
encodeRecordArray([H|T],Res, Encode)->
  JSON= Encode(H),
  Put=[JSON|","],
  encodeRecordArray(T,[Put|Res], Encode).