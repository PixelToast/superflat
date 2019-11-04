import 'dart:typed_data';
import 'dart:web_gl';

import 'package:superflat/gl.dart';
import 'package:vector_math/vector_math.dart';

class SpriteGLObject extends GLObject {
  List<String> vertAssets;
  List<String> fragAssets;

  SpriteGLObject(this.texture, {this.matrix,
    this.vertAssets = const ["shader/sprite/vert.glsl"],
    this.fragAssets = const ["shader/sprite/frag.glsl"]
  }) {
    matrix ??= Matrix4.identity();
  }

  Texture texture;
  Matrix4 matrix;
  GLShader shader;

  init() async {
    shader = await GLShader.load(ctx, vertAssets, fragAssets);
  }

  draw() {
    var gl = ctx.gl;
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, texture);
    gl.useProgram(shader.program);
    gl.bindBuffer(WebGL.ARRAY_BUFFER, ctx.app.squareBuf);
    gl.vertexAttribPointer(shader.attributes["aPos"], 2, WebGL.FLOAT, false, 0, 0);
    gl.uniformMatrix4fv(shader.uniforms['uMatrix'], false, matrix.storage);
    gl.uniform1i(shader.uniforms["uTex"], 0);
    gl.drawArrays(WebGL.TRIANGLES, 0, 6);
  }
}