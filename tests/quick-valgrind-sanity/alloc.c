#include <stdlib.h>
#include <valgrind/memcheck.h>

int main(int argc, char *argv[])
{
    void *buffer = malloc(atoi(argv[1])); 
    VALGRIND_DO_LEAK_CHECK;
    free(buffer);
    return 0; 
}
