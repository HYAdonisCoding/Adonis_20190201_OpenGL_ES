//
//  CCView.m
//  Adonis_20190201_OpenGL_ES
//
//  Created by Adonis_HongYang on 2019/2/11.
//  Copyright © 2019年 Nikoyo (China）Electronics Systems Co., Ltd. All rights reserved.
//
/**  不采用GLBaseEffect,使用编译链接自定义shader,用简单GLSL语言来实现顶点着色器\片元着色器.并且实现图形简单变换
 思路:
 1.创建图层
 2.创建上下文
 3.清空缓存区
 4.设置RenderBuffer,FrameBuffer
 5.开始绘制
 */

#import "CCView.h"
#import <OpenGLES/ES2/gl.h>

@interface CCView ()

/** myEagLayer */
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, strong) EAGLContext *myContext;
/** myColorRenderBuffer */
@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;
@property (nonatomic, assign) GLuint myPrograme;
@end

@implementation CCView

- (void)layoutSubviews {
    //1设置图层
    [self setUpLayer];
    
    //2.创建上下文
    [self setUpContext];
    
    //3.清空缓存区
    [self deleteRenderAndFraneBuffer];
    
    //4设置RenderBuffer
    [self setUpRenderBuffer];
    
    //5设置FrameBuffer
    [self setUpFrameBuffer];
    
    //6.开始绘制
    [self renderLayer];
}

#pragma mark - 6开始绘制
- (void)renderLayer {
    //1.开始要写顶点着色器\片元着色器
    //Vertex Shader
    //Fragment Shaer
    
    //已经写好了顶点shaderv.vsh\片元着色器shaderf.fsh
    glClearColor(.0f, 1.0f, .0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //2.设置视口大小
    GLfloat scale = [UIScreen mainScreen].scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //3.读取顶点\片元着色器程序
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    //NSLog(@"vertFile: %@, fragFile: %@", vertFile, fragFile);
    
    //4.加载shader
    self.myPrograme = [self LoadShader:vertFile withFrag:fragFile];
    
    //5.链接
    glLinkProgram(self.myPrograme);
    
    //获取link的状态
    GLint linkStatus;
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    
    //判断link是否失败
    if (linkStatus == GL_FALSE) {
        //获取失败信息
        GLchar message[512];
        glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
        
        //将C语言字符串-> OC
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error: %@", messageStr);
        
        return;
    }
    
    //5.使用program
    glUseProgram(self.myPrograme);
    
    //6.设置顶点
    GLfloat attrArr[] = {
        0.5f, -0.5f, 1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, 1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, 1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, 1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, 1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, 1.0f,     1.0f, 0.0f,
    };
    
    /** --------------处理顶点数据-------------- */
    GLuint attrBuffer;
    //申请一个缓存标记
    glGenBuffers(1, &attrBuffer);
    
    //绑定缓存区
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    
    //将顶点缓冲区的CPU内存复制到GPU内存中
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    
    //2.
    glEnableVertexAttribArray(position);
    
    //3.设置读取方式
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    
    /** --------------处理纹理数据-------------- */
    //1.获取纹理的位置
    GLuint textCoor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    
    //2.
    glEnableVertexAttribArray(textCoor);
    
    //3.设置读取方式
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
    //加载纹理
    //通过一个自定义方法来解决加载纹理的方法
    [self setupTexture:@"timg"];
    
    //1.直接用3D数学公式来实现旋转
    //2.Uniform
    
    //旋转!!! 矩阵->Uniform 传递到vsh,fsh
    
    //需求:旋转10°->弧度
    float radians = 180 * M_PI / 180.0f;
    
    //旋转的矩阵公式
    float s = sin(radians);
    float c = cos(radians);
    
    //构建旋转矩阵 - 沿着Z轴旋转
    GLfloat zRotation[16] = {
        c, -s, 0, 0,
        s, c, 0, 0,
        0, 0, 1.0, 0,
        0, 0, 0, 1.0
    };
    
    //获取位置
    GLuint rotate = glGetUniformLocation(self.myPrograme, "rotateMatrix");
    
    //将这个矩阵通过Uniform传递进去
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    //绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

#pragma mark - 5设置frameBuffer
- (void)setUpFrameBuffer {
    //1.定义缓存区
    GLuint buffer;
    
    //2.申请一个缓存标记
    glGenRenderbuffers(1, &buffer);
    
    //3.
    self.myColorFrameBuffer = buffer;
    
    //4.
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    //5.将_myColorRenderBuffer 通过glFramebufferRenderbuffer 绑定到附着点上GL_COLOR_ATTACHMENT0(颜色附着点)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

#pragma mark - 设置RenderBuffer
- (void)setUpRenderBuffer {
    //1.定义缓存区
    GLuint buffer;
    
    //2.申请一个缓存标记
    glGenRenderbuffers(1, &buffer);
    
    //3.
    self.myColorRenderBuffer = buffer;
    
    //4.将标识符绑定
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //5.
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
}

#pragma mark - 3清空缓存区
- (void)deleteRenderAndFraneBuffer {
    /*
     可参考PPT
     buffer分为FrameBuffer 和 Render Buffer 2大类.
     frameBuffer(FBO) 相当于renderBuffer的管理者,
     
     renderBuffer又分为三类: colorBuffer,depthBuffer,stencilBuffer
     
     常用函数
     1.绑定buffer标识
     glGenBuffers(GLsizei n, GLuint *buffers)
     glGenRenderbuffers(GLsizei n, GLuint *renderbuffers)
     glGenFramebuffers(GLsizei n, GLuint *framebuffers)
    
     2.绑定空间
     glBindBuffer (GLenum target, GLuint buffer);
     glBindRenderbuffer(GLenum target, GLuint renderbuffer)
     glBindFramebuffer(GLenum target, GLuint framebuffer)
     
     3.删除缓存区空间
     glDeleteBuffers(1, &_myColorRenderBuffer);
     */
    
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}


#pragma mark - 2创建上下文
- (void)setUpContext {
    //1.指定API版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    
    //2.创建图形上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    
    //3.判断是否创建成果
    if (context == NULL) {
        NSLog(@"Create Context Failed!");
        return;
    }
    
    //4.设置图形上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"SetCurrentContext Failed!");
        return;
    }
    
    //5.将局部的context->全局的
    self.myContext = context;
}

#pragma mark - 1设置图层
- (void)setUpLayer {
    //1.设置图层
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    //2.设置比例因子
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    
    //3.默认是透明的, 如果想要其可见要设置为不透明
    self.myEagLayer.opaque = YES;
    
    //4.描述属性
    /*
     kEAGLDrawablePropertyRetainedBacking
     表示绘图表面显示后,是否保留其内容,一般设置为false;
     它是一个key值,通过一个NSNumber包装bool值.
     kEAGLDrawablePropertyColorFormat:绘制对象内部的颜色缓存区格式
     kEAGLColorFormatRGBA8:32位RGBA的颜色, 4*8=32;
     kEAGLColorFormatRGB565:16位RGB的颜色
     kEAGLColorFormatSRGBA8:SRGB,
     */
    self.myEagLayer.drawableProperties =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:false], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark -- shader
- (GLuint)setupTexture:(NSString *)fileName {
    //1.获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    
    //2.判断这个图片是否获取成功
    if (spriteImage == nil) {
        NSLog(@"Failed to load image %@ !", fileName);
        exit(0);
    }
    
    //读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //4.计算图片字节数width * height * 4 (RGBA)
    //malloc calloc (C语言中空间开辟) alloc(oc)
    GLubyte *spriteData = calloc(width * height * 4, sizeof(GLubyte));
    
    //5.创建上下文
    /** CGBitmapContextCreate(void * _Nullable data, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow, CGColorSpaceRef  _Nullable space, uint32_t bitmapInfo)
     参数:
     1.data,要渲染的图像的内存地址
     2.width,宽
     3.height,高
     4.bitsPerComponent,像素中颜色组件的位数
     5.bytesPerRow,一行需要占用多大的内存
     6.space,颜色空间
     7.bitmapInfo
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    //6.
    CGRect rect = CGRectMake(0, 0, width, height);
    
    //使用默认d方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //绘制完释放
    CGContextRelease(spriteContext);
    
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //设置纹理的相关参数
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    //环绕方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //载入纹理
    /** glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels)
     参数列表:
     1.target,GL_TEXTURE_1D\GL_TEXTURE_2D\GL_TEXTURE_3D
     2.level,加载的层次,一般为0
     3.internalformat,颜色组件
     4.width,
     5.height,
     6.border,0
     7.format,
     8.type,存储数据的类型
     8.pixels,指向纹理数据的指针
     */
    GLfloat fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(spriteData);
    
    return 0;
    
}

#pragma mark - 加载shader
- (GLuint)LoadShader:(NSString *)vert withFrag:(NSString *)frag {
    //1.定义两个临时着色器对象
    GLuint verShader, fragShader;
    GLuint program = glCreateProgram();
    
    //2.编译shader
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //3.创建最终程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //4.释放已使用完的verShader,fragShader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    
    return program;
}

#pragma mark - 编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取shader路径
    NSString *context = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    //将OC字符串转换成C语言字符串
    const GLchar *source = (GLchar *)[context UTF8String];
    
    //2.创建Shader
    *shader = glCreateShader(type);
    
    //3.将着色器的代码附着到shader上
    glShaderSource(*shader, 1, &source, NULL);
    
    //4.将着色器代码编译成目标代码
    glCompileShader(*shader);
}



@end
