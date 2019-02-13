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
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface CCView ()

/** myEagLayer */
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, strong) EAGLContext *myContext;
/** myColorRenderBuffer */
@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;

@property (nonatomic, assign) GLuint myProgram;
@property (nonatomic, assign) GLuint myVertices;

@end

@implementation CCView
{
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer *myTimer;
}

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
    glClearColor(.0f, .0f, .0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //2.设置视口大小
    GLfloat scale = [UIScreen mainScreen].scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //3.读取顶点\片元着色器程序
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    //NSLog(@"vertFile: %@, fragFile: %@", vertFile, fragFile);
    //判断self.myProgram是否存在,存在则清空其文件
    if (self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    //4.加载shader //加载程序到myProgram中来。
    self.myProgram = [self LoadShader:vertFile withFrag:fragFile];
    
    //5.链接
    glLinkProgram(self.myProgram);
    
    //获取link的状态
    GLint linkStatus;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkStatus);
    
    //判断link是否失败
    if (linkStatus == GL_FALSE) {
        //获取失败信息
        GLchar message[256];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        
        //将C语言字符串-> OC
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error: %@", messageStr);
        
        return;
    }
    
    //5.使用program
    glUseProgram(self.myProgram);
    
    //创建绘制索引数组
    GLuint indices[] = {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    //判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    
    //6.设置顶点    前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArr[] = {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点
    };
    
    /** --------------处理顶点数据-------------- */
    
    //绑定缓存区
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    
    //将顶点缓冲区的CPU内存复制到GPU内存中
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //将顶点数据通过myPrograme中的传递到顶点着色程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.2.告诉OpenGL ES,通过glEnableVertexAttribArray，3.最后数据是通过glVertexAttribPointer传递过去的。
    //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    
    //2.
    glEnableVertexAttribArray(position);
    
    //3.设置读取方式 索引绘图
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    
    /** --------------处理纹理数据-------------- */
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //注意：第二参数字符串必须和shaderv.glsl中的输入变量：positionColor保持一致
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    
    //2.
    glEnableVertexAttribArray(positionColor);
    
    //3.设置读取方式
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (GLfloat *)NULL + 3);
    
    //注意，想要获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    /*
     一个一致变量在一个图元的绘制过程中是不会改变的，所以其值不能在glBegin/glEnd中设置。一致变量适合描述在一个图元中、一帧中甚至一个场景中都不变的值。一致变量在顶点shader和片断shader中都是只读的。首先你需要获得变量在内存中的位置，这个信息只有在连接程序之后才可获得
     */
    //找到myProgram中的projectionMatrix、modelViewMatrix 2个矩阵的地址。如果找到则返回地址，否则返回-1，表示没有找到2个对象。
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    
    //创建4X4矩阵
    KSMatrix4 projectionMatrix;
    
    //获取单元矩阵
    ksMatrixLoadIdentity(&projectionMatrix);
    
    //计算纵横比
    float aspect = width / height;
    
    //获取透视矩阵
    /*
     参数1：矩阵
     参数2：视角，度数为单位
     参数3：纵横比
     参数4：近平面距离
     参数5：远平面距离
     */
    ksPerspective(&projectionMatrix, 30.0f, aspect, 5.0f, 20.0f);
    
    //设置glsl里面的投影矩阵
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&projectionMatrix.m[0][0]);
    
    //开启剔除操作效果
    glEnable(GL_CULL_FACE);
    
    //创建4*4矩阵,模型视图
    KSMatrix4 modelViewMatrix;
    
    ksMatrixLoadIdentity(&modelViewMatrix);
    
    //平移-10,Z轴
    ksTranslate(&modelViewMatrix, .0f, .0f, -10.0f);
    
    //创建旋转矩阵
    KSMatrix4 rotationMatrix;
    ksMatrixLoadIdentity(&rotationMatrix);
    
    //旋转
    ksRotate(&rotationMatrix, xDegree, 1.0f, .0f, .0f);
    ksRotate(&rotationMatrix, yDegree, .0f, 1.0f, .0f);
    ksRotate(&rotationMatrix, zDegree, .0f, .0f, 1.0f);
    
    //把变换矩阵相乘，注意先后顺序 ，将平移矩阵与旋转矩阵相乘，结合到模型视图
    ksMatrixMultiply(&modelViewMatrix, &rotationMatrix, &modelViewMatrix);
    
    // 加载模型视图矩阵 modelViewMatrixSlot
    //设置glsl里面的投影矩阵
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat *)&modelViewMatrix.m[0][0]);
    
    //使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
     GL_POINTS
     GL_LINES
     GL_LINE_LOOP
     GL_LINE_STRIP
     GL_TRIANGLES
     GL_TRIANGLE_STRIP
     GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
     GL_BYTE
     GL_UNSIGNED_BYTE
     GL_SHORT
     GL_UNSIGNED_SHORT
     GL_INT
     GL_UNSIGNED_INT
     indices：绘制索引数组
     
     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    
    //要求本地窗口系统显示OpenGL ES渲染<目标>
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
    
    //frame buffer仅仅是管理者，不需要分配空间；render buffer的存储空间的分配，对于不同的render buffer，使用不同的API进行分配，而只有分配空间的时候，render buffer句柄才确定其类型
    //为color renderBuffer 分配空间
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
        NSLog(@"Set CurrentContext Failed!");
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
    self.myEagLayer.drawableProperties =  [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithBool:false], kEAGLDrawablePropertyRetainedBacking,
                                           kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    
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

- (IBAction)xCicked:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bX = !bX;
}

- (IBAction)yClicked:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bY = !bY;
}
- (IBAction)zClicked:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bZ = !bZ;
}

- (void)reDegree {
    xDegree += bX *5;
    yDegree += bY *5;
    zDegree += bZ *5;
    
    //重新渲染
    [self renderLayer];
}
@end
