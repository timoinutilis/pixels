//
//  main.m
//  convertfont
//
//  Created by Timo Kloss on 22/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        if (argc < 2)
        {
            printf("missing parameter\n");
        }
        else
        {
            CGDataProviderRef source = CGDataProviderCreateWithFilename(argv[1]);
            if (!source)
            {
                printf("file error\n");
            }
            else
            {
                CGImageRef image = CGImageCreateWithPNGDataProvider(source, NULL, FALSE, kCGRenderingIntentDefault);
                if (!image)
                {
                    printf("image error\n");
                }
                else
                {
                    size_t width = CGImageGetWidth(image);
                    size_t height = CGImageGetHeight(image);
                    printf("image %dx%d\n", (int)width, (int)height);
                    
                    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(image));
                    if (!imageData)
                    {
                        printf("image data error\n");
                    }
                    else
                    {
                        printf("converting font...\n");
                        
                        NSMutableArray *charsX = [NSMutableArray array];
                        
                        const UInt8 *bytes = CFDataGetBytePtr(imageData);
                        size_t bytesPerRow = CGImageGetBytesPerRow(image);
                        int lastMarker = -1;
                        
                        for (CFIndex x = 0; x < width; x++)
                        {
                            int marker = bytes[(height - 1) * bytesPerRow + (x<<2)];
                            if (marker != lastMarker)
                            {
                                [charsX addObject:@(x)];
                                lastMarker = marker;
                            }
                            
                            int rowBits = 0;
                            for (CFIndex y = 0; y < height - 1; y++)
                            {
                                UInt8 pixel = bytes[y * bytesPerRow + (x<<2)];
                                if (pixel > 127)
                                {
                                    rowBits |= (1<<y);
                                }
                            }
                            printf("0x%X, ", rowBits);
                        }
                        [charsX addObject:@(width)];
                        
                        printf("\n");
                        
                        for (int i = 0; i < charsX.count - 1; i++)
                        {
                            NSNumber *number = charsX[i];
                            printf("%d, ", number.intValue);
                        }

                        printf("\n");
                        
                        for (int i = 1; i < charsX.count; i++)
                        {
                            NSNumber *lastNumber = charsX[i-1];
                            NSNumber *number = charsX[i];
                            printf("%d, ", number.intValue - lastNumber.intValue);
                        }
                        
                        printf("\n");

                        CFRelease(imageData);
                    }
                    
                    CGImageRelease(image);
                }
                CGDataProviderRelease(source);
            }
        }
    }
    return 0;
}
