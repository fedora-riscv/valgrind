#include <stdio.h>

void f (int x);

int
main (int argc, char *argv[])
{
  int a;

  f(a);

  return 0;
}

void
f (int x)
{
  static int var __attribute__ ((used)) = 42;
  if(x)
    puts("hello, world");
}
