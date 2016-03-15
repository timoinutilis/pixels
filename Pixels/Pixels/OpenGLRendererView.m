//
//  OpenGLRendererView.m
//  Pixels
//
//  Created by Timo Kloss on 14/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "OpenGLRendererView.h"
#import "Renderer.h"

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

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@interface OpenGLRendererView()

@property (nonatomic) GLKBaseEffect *effect;

@end

@implementation OpenGLRendererView {
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _texName;
    GLubyte *_textureData;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    int rendererSize = 64;
    
    _textureData = (GLubyte *)calloc(rendererSize * rendererSize * 3, sizeof(GLubyte));
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    
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
}

- (void)dealloc
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    
    free(_textureData);
}

- (void)renderTextureData
{
    int rendererSize = 64;
    int i = 0;
    for (int y = 0; y < rendererSize; y++)
    {
        for (int x = 0; x < rendererSize; x++)
        {
            uint32_t color = [self.renderer screenColorAtX:x Y:y];
            _textureData[i++] = (color >> 16) & 0xFF;
            _textureData[i++] = (color >> 8) & 0xFF;
            _textureData[i++] = (color) & 0xFF;
            
        }
    }
}

- (void)drawRect:(CGRect)rect
{
    int rendererSize = 64;
    
    [self renderTextureData];
    
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, rendererSize, rendererSize, 0, GL_RGB, GL_UNSIGNED_BYTE, _textureData);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord));

    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}

@end
