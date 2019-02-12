//vertex shader -- 顶点着色器

/** 顶点数据 */
attribute vec4 position;

/** 纹理 */
attribute vec2 textCoordinate;

/** 旋转矩阵 */
uniform mat4 rotateMatrix;

/** 将纹理数据传递到片元着色器中去 */
varying lowp vec2 varyTextCoord;

void main() {
    //将textCoordinate通过varyTextCoord传递到片元着色器中去
    varyTextCoord = textCoordinate;
    
    vec4 vPos = position;
    
    //将顶点应用旋转变换
    vPos = vPos * rotateMatrix;
    
    //內建变量, gl_Position 必须赋值
    gl_Position = vPos;
}
