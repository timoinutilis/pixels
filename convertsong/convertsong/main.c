//
//  main.c
//  convertsong
//
//  Created by Timo Kloss on 22/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#include <stdio.h>

void readNote(char *line, int channel, int *pitch, int *instr);

int main(int argc, const char * argv[])
{
    if (argc < 2)
    {
        printf("missing parameter\n");
    }
    else
    {
        FILE *input = fopen(argv[1], "r");
        if (!input)
        {
            printf("could not open file\n");
        }
        else
        {
            char inputLine[100];
            while (!feof(input))
            {
                if (fgets(inputLine, 100, input))
                {
                    printf("DATA ");
                    for (int channel = 0; channel < 3; channel++)
                    {
                        int pitch = 0, instr = 0;
                        readNote(inputLine, channel, &pitch, &instr);
                        if (channel > 0)
                        {
                            printf(",");
                        }
                        printf("%d,%d", pitch, instr);
                    }
                    printf("\n");
                }
            }
        }
    }
    
    return 0;
}

void readNote(char *line, int channel, int *pitch, int *instr)
{
    int offset = 4 + channel * 10;
    char note1 = line[offset];
    char note2 = line[offset + 1];
    char notes1[] = {'-', 'C', 'C', 'D', 'D', 'E', 'F', 'F', 'G', 'G', 'A', 'A', 'B'};
    char notes2[] = {'-', '-', '#', '-', '#', '-', '-', '#', '-', '#', '-', '#', '-'};
    for (int i = 0; i < 13; i++)
    {
        if (note1 == notes1[i] && note2 == notes2[i])
        {
            if (i == 0)
            {
                if (line[offset + 6] == 'C')
                {
                    // stop sound
                    *pitch = 0;
                }
                else
                {
                    // space
                    *pitch = -1;
                }
            }
            else
            {
                // sound
                *pitch = i;
            }
            break;
        }
    }
    
    if (*pitch > 0)
    {
        int octave = line[offset + 2] - '0';
        *pitch = *pitch + (octave - 1) * 12;
    }
    
    *instr = line[offset + 4] - '0';
}
