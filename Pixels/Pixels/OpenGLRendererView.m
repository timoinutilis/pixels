//
//  OpenGLRendererView.m
//  Pixels
//
//  Created by Timo Kloss on 14/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "OpenGLRendererView.h"
#import "Renderer.h"
#import "UIImage+Utils.h"

typedef struct {
    float Position[3];
    float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 1}},
    {{1, 1, 0}, {1, 0}},
    {{-1, 1, 0}, {0, 0}},
    {{-1, -1, 0}, {0, 1}}
};

const GLushort Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@interface OpenGLRendererView()
@property (nonatomic) GLKBaseEffect *effect;
@property (nonatomic) NSMutableArray *snapshots;
@property (nonatomic) CFAbsoluteTime lastSnapshotTime;
@property (nonatomic) CIContext *ciContext;
@end

@implementation OpenGLRendererView {
    BOOL _initialized;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _texName;
    GLubyte *_textureData;
    int _currentSize;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.ciContext = [CIContext contextWithOptions:nil];
    
    // OpenGL
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.effect = [[GLKBaseEffect alloc] init];
}

- (void)dealloc
{
    if (_initialized)
    {
        [EAGLContext setCurrentContext:self.context];
        glDeleteBuffers(1, &_vertexBuffer);
        glDeleteBuffers(1, &_indexBuffer);
        glDeleteTextures(1, &_texName);
    }
    
    if (_textureData)
    {
        free(_textureData);
    }
}

- (void)renderTextureData
{
    if (self.renderer.displaySize != _currentSize)
    {
        if (_textureData)
        {
            free(_textureData);
        }
        _currentSize = self.renderer.displaySize;
        _textureData = (GLubyte *)calloc(_currentSize * _currentSize * 3, sizeof(GLubyte));
    }
    
    GLubyte *dataByte = _textureData;
    for (int y = 0; y < _currentSize; y++)
    {
        for (int x = 0; x < _currentSize; x++)
        {
            uint32_t color = [self.renderer screenColorAtX:x Y:y];
            *dataByte = (color >> 16) & 0xFF;
            ++dataByte;
            *dataByte = (color >> 8) & 0xFF;
            ++dataByte;
            *dataByte = (color) & 0xFF;
            ++dataByte;
        }
    }
}

- (void)drawRect:(CGRect)rect
{
    [self renderTextureData];
    
    if (!_initialized)
    {
        glGenBuffers(1, &_vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
        
        glGenBuffers(1, &_indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
        
        glGenTextures(1, &_texName);
        glBindTexture(GL_TEXTURE_2D, _texName);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        
        self.effect.texture2d0.name = _texName;
        self.effect.texture2d1.enabled = GL_FALSE;

        glClearColor(1.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord));

        _initialized = YES;
    }
    
    [self.effect prepareToDraw];
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _currentSize, _currentSize, 0, GL_RGB, GL_UNSIGNED_BYTE, _textureData);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_SHORT, 0);
}

#pragma mark - Snapshots

- (void)updateSnapshots
{
    if (self.shouldMakeSnapshots && CFAbsoluteTimeGetCurrent() - self.lastSnapshotTime >= 1)
    {
        [self makeSnapshot];
        self.lastSnapshotTime = CFAbsoluteTimeGetCurrent();
        if (self.snapshots.count >= 120)
        {
            self.shouldMakeSnapshots = NO;
        }
    }
}

- (void)makeSnapshot
{
    if (self.renderer)
    {
        int size = self.renderer.displaySize;
        
        int numPixels = size * size;
        uint32_t data[numPixels];
        
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                data[y * size + x] = [self.renderer screenColorAtX:x Y:y] | 0xFF000000;
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
    UIImage *image = nil;
    if (self.snapshots)
    {
        // find non empty snapshot from the middle
        int index = (int)(self.snapshots.count / 2);
        NSData *best = self.snapshots[index];
        
        if (![self snapshotIsOkay:best])
        {
            while (index + 1 < self.snapshots.count)
            {
                index++;
                if ([self snapshotIsOkay:self.snapshots[index]])
                {
                    best = self.snapshots[index];
                    break;
                }
            }
        }
        
        // create image
        image = [self imageWithSnapshot:best];
    }
    
    self.shouldMakeSnapshots = NO;
    return image;
}

- (NSArray <UIImage *> *)imagesFromSnapshots:(int)amount
{
    if (self.snapshots)
    {
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:amount];
        float step = (float)self.snapshots.count / amount;
        int i = 0;
        while (i < self.snapshots.count)
        {
            NSData *data = self.snapshots[i];
            UIImage *image = [self imageWithSnapshot:data];
            [images addObject:image];
            i = ceilf(i + step);
        }
        return images;
    }
    return nil;
}

- (BOOL)snapshotIsOkay:(NSData *)data
{
    int rendererSize = [self rendererSizeForSnapshot:data];
    int numPixels = rendererSize * rendererSize;
    uint32_t *pixelData = (uint32_t *)data.bytes;
    
    for (int i = 1; i < numPixels; i++)
    {
        if (pixelData[i] != pixelData[i-1])
        {
            return YES;
        }
    }
    return NO;
}

- (UIImage *)imageWithSnapshot:(NSData *)data
{
    int rendererSize = [self rendererSizeForSnapshot:data];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CIImage *ciImage = [CIImage imageWithBitmapData:data
                                        bytesPerRow:rendererSize * sizeof(uint32_t)
                                               size:CGSizeMake(rendererSize, rendererSize)
                                             format:kCIFormatBGRA8
                                         colorSpace:colorSpace];
    
    CGImageRef cgImage = [self.ciContext createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    image = [image imageWithSize:CGSizeMake(128, 128) scale:1.0 quality:kCGInterpolationNone];
    
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (int)rendererSizeForSnapshot:(NSData *)data
{
    return sqrtf(data.length / sizeof(uint32_t));
}

@end
