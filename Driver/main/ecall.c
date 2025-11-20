#include <stdio.h>
#include <stdint.h>
#include <string.h>


int print_int(int value)
{
    printf("%d\n", value);
    return 0;
}

int print_float(float value)
{
    printf("%f\n", value);
    return 0;
}

int print_double(double value)
{
    printf("%lf\n", value);
    return 0;
}
int print_string(char *value)
{
    printf("%s\n", value);
    return 0;
}