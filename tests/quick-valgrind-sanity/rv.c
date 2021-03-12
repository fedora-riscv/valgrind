#include <valgrind/valgrind.h>
#include <stdio.h>

int main()
{
    if(RUNNING_ON_VALGRIND)
        puts("I'm running on valgrind \\o/");
    else
        puts("I'm not running on valgrind /o\\");

    return 0;
}
