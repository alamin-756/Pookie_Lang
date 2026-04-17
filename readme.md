//windows er 
// gcc pookie.tab.c lex.yy.c -o pookie -lfl

//mac 

bison -d pookie.y
flex pookie.l
gcc pookie.tab.c lex.yy.c -o pookie
./pookie < test.pookie




bison -d pookie.y
flex pookie.l
gcc lex.yy.c pookie.tab.c ast.c interpreter.c -o pookie
./pookie < test_all.pookie