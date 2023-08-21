/* To this day I have no idea how to write a makefile.
 Run as
    test: 
        echo "\n\n" && gcc -Wall shield.c -o shield.o && ./shield.o

    library:
        gcc -c -fPIC shield.c -o shield.o && gcc -shared -o libshield.so shield.o

*/

#include<stdio.h>
#include<stdbool.h>
#include "shield_dump.c"

const int OUT_OF_BOUNDS = -1;

int get_index(int indices[])
{
    int index = 0;
    int multiplier = 1;
    int dim;
    for (dim = 0; dim < dimensions; dim++)
    {
        index += multiplier*indices[dim];
        multiplier *= size[dim];
    }
    return grid[index] - char_offset;
}

int box(double  value, int dim)
{
    return (int) ((value - lower_bounds[dim])/granularity[dim]);
}

int get_value_from_vector(double s[])
{
    int indices[dimensions];
    int dim;
    for (dim = 0; dim < dimensions; dim++)
    {
        if (s[dim] < lower_bounds[dim] || s[dim] >= upper_bounds[dim])
        {
            return OUT_OF_BOUNDS;
        }
        indices[dim] = box(s[dim], dim);
    }

    return get_index(indices);
}

int get_value(double velocity, double velocityFront, double distance)
{
    return get_value_from_vector((double[]){velocity, velocityFront, distance});
}

int main() {
    return 0;
}