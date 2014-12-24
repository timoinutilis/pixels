//
//  RendererView.m
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "RendererView.h"
#import <CoreGraphics/CoreGraphics.h>
#import "Renderer.h"

@interface RendererView ()

@property NSMutableArray *snapshots;
@property CFAbsoluteTime lastSnapshotTime;

@end

@implementation RendererView

- (void)drawRect:(CGRect)rect
{
    if (self.shouldMakeThumbnail && CFAbsoluteTimeGetCurrent() - self.lastSnapshotTime >= 1)
    {
        [self makeSnapshot];
        self.lastSnapshotTime = CFAbsoluteTimeGetCurrent();
        if (self.snapshots.count >= 10)
        {
            self.shouldMakeThumbnail = NO;
        }
    }
    
    [self renderWithSize:self.bounds.size data:nil];
}

- (void)renderWithSize:(CGSize)size data:(NSData *)data
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetFillColorSpace(context, colorSpace);
    CGColorSpaceRelease(colorSpace);
    
    CGFloat components[] = {0.0, 0.0, 0.0, 1.0};
    CGRect myRect;
    
    myRect.origin.x = 0;
    myRect.origin.y = 0;
    myRect.size.width = size.width;
    myRect.size.height = size.height;
    CGContextSetFillColor(context, components);
    CGContextFillRect(context, myRect);
    
    if (self.renderer)
    {
        int rendererSize = self.renderer.size;
        uint32_t *dataPixels = nil;
        if (data)
        {
            dataPixels = (uint32_t *)data.bytes;
        }
        
        CGFloat pixelWidth = size.width / rendererSize;
        CGFloat pixelHeight = size.height / rendererSize;
        myRect.size.width = pixelWidth * 0.99;
        myRect.size.height = pixelHeight * 0.99;
        
        for (int y = 0; y < rendererSize; y++)
        {
            myRect.origin.y = y * pixelHeight;
            for (int x = 0; x < rendererSize; x++)
            {
                myRect.origin.x = x * pixelWidth;
                uint32_t color = dataPixels != nil ? dataPixels[y * rendererSize + x] : [self.renderer screenColorAtX:x Y:y];
                
                components[0] = ((color >> 16) & 0xFF) / 255.0;
                components[1] = ((color >> 8) & 0xFF) / 255.0;
                components[2] = (color & 0xFF) / 255.0;
                CGContextSetFillColor(context, components);
                CGContextFillRect(context, myRect);
            }
        }
    }
}

- (void)makeSnapshot
{
    if (self.renderer)
    {
        int size = self.renderer.size;
        
        int numPixels = size * size;
        uint32_t data[numPixels];
        
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                data[y * size + x] = [self.renderer screenColorAtX:x Y:y];
            }
        }
        
        if (!self.snapshots)
        {
            self.snapshots = [NSMutableArray array];
        }
        NSData *snapshotData = [NSData dataWithBytes:data length:(numPixels * 4)];
        [self.snapshots addObject:snapshotData];
    }
}

- (UIImage *)imageFromBestSnapshot
{
    UIImage *thumb = nil;
    if (self.snapshots)
    {
        // find best snapshot
        NSData *best;
        int bestQuality = -1;
        for (NSData *snapshot in self.snapshots)
        {
            int quality = [self qualityOfSnapshot:snapshot];
            if (quality > bestQuality)
            {
                best = snapshot;
                bestQuality = quality;
            }
        }
        
        // create image
        CGSize size = CGSizeMake(self.renderer.size * 4, self.renderer.size * 4);
        UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
        [self renderWithSize:size data:best];
        thumb = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    self.shouldMakeThumbnail = NO;
    return thumb;
}

- (int)qualityOfSnapshot:(NSData *)data
{
    int changes = 0;
    int size = self.renderer.size;
    int numPixels = size * size;
    uint32_t *pixelData = (uint32_t *)data.bytes;
    
    for (int i = 1; i < numPixels; i++)
    {
        if (pixelData[i] != pixelData[i-1])
        {
            changes++;
        }
    }
    return changes;
}

@end
