#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#define NUM_DIGITS 10

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Incorrect number of argument\n", argv[0]);
        return 1;
    }

    char *filename = argv[1];
    int num_digits = atoi(argv[2]);

    if (num_digits <= 0)
    {
        printf("Error:must be a positive integer\n");
        return 1;
    }

    FILE *fp = fopen(filename, "r");

    if (fp == NULL)
    {
        printf("Error: cannot open file '%s'\n", filename);
        return 1;
    }

    int digit_counts[NUM_DIGITS] = {0};
    char c;

    for (int i = 0; i < num_digits; i++)
    {
        c = fgetc(fp);
        if (!isdigit(c))
        {
            printf("Error: file contains non-digit characters\n");
            return 1;
        }
        digit_counts[c - '0']++;
    }

    fclose(fp);

    printf("Digit counts: ");
    for (int i = 0; i < NUM_DIGITS; i++)
    {
        printf("%d:%d ", i, digit_counts[i]);
    }
    printf("\n");

    return 0;
}