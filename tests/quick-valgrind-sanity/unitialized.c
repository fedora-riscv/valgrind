/* valgrind ./a.out 0 ~> no error */
/* valgrind ./a.out 1 ~> error */

#include <stdlib.h>

struct something {
    char c;
    int x;
};
/* === 8 bytes ===
 * 42
 * garbage
 * garbage
 * garbage
 * 42
 * 42
 * 42
 * 42
 */


int main(int argc, char *argv[])
{
    struct something st = { 0x2A, 0x2A2A2A2A };

    struct something st_copy = st;

    return (int) *(&(st_copy.c)+atoi(argv[1]));
}
/* error generated after main returns */
