-module(common_validation_service).

-export([is_object_valid/2,
		is_field_valid/3]).

%%Обобщённый валидатор записей - позволяет автоматически проверить каждое поле поданной записи
%На вход получает искомый объект и массив функций обратного вызова All

%Каждый элемент All содержит функцию валидации одного поля record
%Последовательность функций должна полностью повторять последовательность полей исходной записи
%каждая функция должна быть логическим предикатом
is_object_valid(Obj,All)->
	is_object_valid(Obj,All,2,tuple_size(Obj),true).
	
is_object_valid(_,_,Field,Max,Res) when Field =:= Max+1->
	Res;
is_object_valid(Obj,[Foo|Tail],Field,Max,Res)->
	Res1=Res and Foo(element(Field,Obj)),
	is_object_valid(Obj,Tail,Field+1,Max,Res1).

%%написать валидацию поля
%%вход: объект, массив функций обратного вызова All, позиция поля в кортеже объекта
%%Field - результат вызова #<record>.<field>
is_field_valid(Obj,All,Field)->
	F = lists:nth(Field-1,All),
	F(element(Field,Obj)).
