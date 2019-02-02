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
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //清楚surface内容,恢复至初始状态
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}


@end
