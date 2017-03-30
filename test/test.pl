fact.
fact(arg1, arg2, ar3).
fact(arg).

fact([X]).
fact([X|Y]).
fact([A,[A]]).
fact([A,[A]|[]]).
fact([]).
fact([1,-2,3.0]).

testComp :- 3 < 4.
testComp :- 3 =:= 3.
testComp :- 4 >= 3.
testComp :- 3 =< 4.
testComp :- 3 =\= 4.
testComp :- 4 > 3.
