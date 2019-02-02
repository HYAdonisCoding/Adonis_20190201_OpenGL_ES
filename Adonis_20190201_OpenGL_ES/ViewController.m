//
//  ViewController.m
//  Adonis_20190201_OpenGL_ES
//
//  Created by Adonis_HongYang on 2019/2/2.
//  Copyright © 2019年 Nikoyo (China）Electronics Systems Co., Ltd. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface ViewController () <GLKViewDelegate>
{
    /** 苹果在ios平台下实现的opengles渲染层，用于渲染结果在目标surface上的更新。 */
    EAGLContext *context;
    /** 着色器或者光照 */
    GLKBaseEffect *mEffect;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.设置OpenGL ES
    [self setUpConfig];
    
    //2.加载顶点数据
    [self uploadVertexArray];
    
    //3.加载纹理
    [self uploadTexture];
}

- (void)setUpConfig {
    //新建OpenGL ES上下文
    context = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES3)];
    
    if (!context) {
        NSLog(@"Failed to create ES context!");
    }
    
    //创建一个OpenGL ES上下文并将其分配给从storyboard加载的视图
    //注意：这里需要把stroyBoard记得添加为GLKView
    GLKView *view = (GLKView *)self.view;
    view.context = context;
    
    //配置视图创建的渲染缓冲区
    /*
     OpenGL ES 有一个缓存区，它用以存储将在屏幕中显示的颜色。你可以使用其属性来设置缓冲区中的每个
     像素的颜色格式。
     默认：GLKViewDrawableColorFormatRGBA8888，即缓存区的每个像素的最小组成部分（RGBA）使用
     8个bit，（所以每个像素4个字节，4*8个bit）。
     GLKViewDrawableColorFormatRGB565,如果你的APP允许更小范围的颜色，即可设置这个。会让你的
     APP消耗更小的资源（内存和处理时间）
     */
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    /*
     OpenGL ES 另一个缓存区，深度缓冲区。帮助我们确保可以更接近观察者的对象显示在远一些的对象前面。
     （离观察者近一些的对象会挡住在它后面的对象）
     默认：OpenGL把接近观察者的对象的所有像素存储到深度缓冲区，当开始绘制一个像素时，它（OpenGL）
     首先检查深度缓冲区，看是否已经绘制了更接近观察者的什么东西，如果是则忽略它（要绘制的像素，
     就是说，在绘制一个像素之前，看看前面有没有挡着它的东西，如果有那就不用绘制了）。否则，
     把它增加到深度缓冲区和颜色缓冲区。
     缺省值是GLKViewDrawableDepthFormatNone，意味着完全没有深度缓冲区。
     但是如果你要使用这个属性（一般用于3D游戏），你应该选择GLKViewDrawableDepthFormat16
     或GLKViewDrawableDepthFormat24。这里的差别是使用GLKViewDrawableDepthFormat16
     将消耗更少的资源，但是当对象非常接近彼此时，你可能存在渲染问题（）
     */
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:context];
    //开启深度测试,就是让离你近的物体可以遮挡离你远多的物体
    glEnable(GL_DEPTH_TEST);
    //设置surface清屏颜色, 也就是渲染到屏幕上的颜色
    glClearColor(.1f, .2f, .3f, 1.0f);
    
}

#pragma mark - 加载顶点数据
- (void)uploadVertexArray {
    //1.设置顶点数组
    /** OpenGLES的世界坐标系是[-1, 1]，故而点(0, 0)是在屏幕的正中间。
     顶点数据，前3个是顶点坐标x,y,z；后面2个是纹理坐标。
     纹理坐标系的取值范围是[0, 1]，原点是在左下角。故而点(0, 0)在左下角，点(1, 1)在右上角
     */
    GLfloat vertexData[] = {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    
    /** 怎样让图片全屏显示
     //开启顶点缓冲区
     //顶点缓存区
     */
    GLuint buffer;
    //申请一个缓存区标识符
    glGenBuffers(1, &buffer);
    //glBindBuffer把标识符绑定到GL_ARRAY_BUFFER上
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    //glBufferData把顶点数据从CPU内存复制到GPUs内存
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    /** 3.设置合适的格式从buffer里读取数据
     默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的，意味着数据在着色器端是不可见的，哪怕数据已经上传到GPU，由glEnableVertexAttribArray启用指定属性，才可在顶点着色器中访问逐顶点的属性数据。glVertexAttribPointer或VBO只是建立CPU和GPU之间的逻辑连接，从而实现了CPU数据上传至GPU。但是，数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
     */
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    /** glVertexAttribPointer 使用来上传顶点数据到显卡的方法（设置合适的格式从buffer里面读取数据）
     index: 指定要修改的顶点属性的索引值
     size : 指定每个顶点属性的组件数量。必须为1、2、3或者4。初始值为4。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a））
     type : 指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
     normalized : 指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
     stride : 指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
     ptr    : 指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0 这个值受到VBO的影响
     VBO,顶点缓存对象
     在不使用VBO的情况下：事情是这样的，ptr就是一个指针，指向的是需要上传到顶点数据指针。通常是数组名的偏移量。
     
     在使用VBO的情况下：首先要glBindBuffer，以后ptr指向的就不是具体的数据了。因为数据已经缓存在缓冲区了。这里的ptr指向的是缓冲区数据的偏移量。这里的偏移量是整型，但是需要强制转换为const GLvoid *类型传入。注意的是，这里的偏移的意思是数据个数总宽度数值。
     
     比如说：这里存放的数据前面有3个float类型数据，那么这里的偏移就是，3*sizeof(float).
     
     最后解释一下，glVertexAttribPointer的工作原理：
     首先，通过index得到着色器对应的变量openGL会把数据复制给着色器的变量。
     以后，通过size和type知道当前数据什么类型，有几个。openGL会映射到float，vec2, vec3 等等。
     由于每次上传的顶点数据不止一个，可能是一次4，5，6顶点数据。那么通过stride就是在数组中间隔多少byte字节拿到下个顶点此类型数据。
     最后，通过ptr的指针在迭代中获得所有数据。
     那么，最最后openGL如何知道ptr指向的数组有多长，读取几次呢。是的，openGL不知道。所以在调用绘制的时候，需要传入一个count数值，就是告诉openGL绘制的时候迭代几次glVertexAttribPointer调用。
     
     (GLfloat *)NULL + 0 指针，指向数组首地址
     */
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    //纹理
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    //指向纹理数据
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
}

#pragma mark - 加载纹理
- (void)uploadTexture {
    //1.获取纹理图片的保存路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"cTest" ofType:@"jpg"];
    
    //纹理坐标是反的
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @(1)};
    
    NSError *error;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:&error];
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
    }
    //着色器
    mEffect = [[GLKBaseEffect alloc] init];
    
    //第一个纹理属性
    mEffect.texture2d0.enabled = GL_TRUE;
    
    //纹理的名字
    mEffect.texture2d0.name = textureInfo.name;
}


#pragma mark - GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(.3f, .6f, 1.0f, 1.0f);
    //清楚surface内容,恢复至初始状态
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //启动着色器
    [mEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}


@end
