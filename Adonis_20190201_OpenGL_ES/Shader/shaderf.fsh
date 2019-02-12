//OpenGL ES 中的3种修饰类型 uniform,attribute,varying

/*
 ---------------------------Uniform---------------------------
 Uniform 是有外部application程序传递给Vertex Shader,fragment Shader变量.
 A.由application 通过函数glUniform**()函数赋值的
 B.在Vertex Shader,fragment Shader 内部中,类似C语言的const.它不能被shader修改
 
 注意:Uniform 变量,shader 只能用不能改!!!
 
 例如:
 uniform mat4 viewProjectMatix;
 uniform mat4 viewMatix;
 unifrom vec3 lightPosition;
 
 ------------------------attribute---------------------------
 attribute 只能在vertex shader中使用,不能在fragment shader中声明attribute变量,也不能被fragment shader使用
 一般attribute 来表示顶点坐标\法线\纹理坐标\顶点颜色
 
 attribute vec4 a_position;
 attribute vec2 a_texCoord0;
 
 注意:attribute 只能在vertex shader中使用.不能在fragment shader中使用
 
 
 ------------------------varying---------------------
 varying,在vertex 和 fragment shader之间传递数据用
 varying vec2 a_texCoord0
 */

//将纹理数据传递到片元着色器去
varying lowp vec2 varyTextCoord;

//2D
uniform sampler2D colorMap;

void main() {
    //內建变量, 必须赋值
    gl_FragColor = texture2D(colorMap, varyTextCoord);
    
}
