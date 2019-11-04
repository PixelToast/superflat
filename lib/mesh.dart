import 'dart:html';
import 'dart:js';
import 'dart:web_gl';

import 'package:superflat/gl.dart';
import 'package:vector_math/vector_math.dart';

abstract class GLMaterial {
  GLViewport ctx;
  GLShader shader;
  void draw(GLViewport ctx);
}

class BasicMaterial extends GLMaterial {
  GLShader shader;
  Map<String, dynamic> uniforms;

  BasicMaterial(this.shader, this.uniforms);

  draw(GLViewport ctx) {
    var gl = ctx.gl;
    gl.useProgram(shader.program);

    var tex = WebGL.TEXTURE0;

    for (var u in uniforms.keys) {
      var v = uniforms[u];
      if (v is Texture) {
        gl.activeTexture(WebGL.TEXTURE0);
        gl.bindTexture(WebGL.TEXTURE_2D, v);
        gl.uniform1i(shader.uniforms[u], 0);
        tex = tex + 1;
      } else if (v is double) {
        gl.uniform1f(shader.uniforms[u], v);
      } else if (v is Vector3) {
        gl.uniform3f(shader.uniforms[u], v.x, v.y, v.z);
      } else if (v is Vector4) {
        gl.uniform4f(shader.uniforms[u], v.x, v.y, v.z, v.w);
      } else if (v is Matrix3) {
        gl.uniformMatrix3fv(shader.uniforms[u], false, v.storage);
      } else if (v is Matrix4) {
        gl.uniformMatrix4fv(shader.uniforms[u], false, v.storage);
      }
    }
  }
}

class MeshGLObject extends GLObject {
  JsObject obj;
  GLMaterial mat;

  MeshGLObject(this.obj, this.mat);

  Vector3 pos = Vector3.zero();
  Vector3 ang = Vector3.zero();
  Vector3 scale = Vector3.zero();

  init() async {
    var gl = ctx.gl;
    var glJs = ctx.glJs;

    (glJs["bindBuffer"] as JsFunction).apply([WebGL.ARRAY_BUFFER, obj["vertexBuffer"]], thisArg: glJs);
    gl.vertexAttribPointer(mat.shader.attributes["aVertexPosition"], obj["vertexBuffer"]["itemSize"], WebGL.FLOAT, false, 0, 0);

    (glJs["bindBuffer"] as JsFunction).apply([WebGL.ARRAY_BUFFER, obj["textureBuffer"]], thisArg: glJs);
    gl.vertexAttribPointer(mat.shader.attributes["aTexCoord"], obj["textureBuffer"]["itemSize"], WebGL.FLOAT, false, 0, 0);

    (context["OBJ"]["initMeshBuffers"] as JsFunction).apply([
      ctx.glJs, obj
    ]);
  }

  draw() {
    var gl = ctx.gl;
    var glJs = ctx.glJs;
    super.draw();

    ctx.mvPush();
    ctx.mvMatrix.add(Matrix4.compose(pos, Quaternion.euler(ang.x, ang.y, ang.z), scale));

    mat.draw(ctx);

    (glJs["bindBuffer"] as JsFunction).apply([WebGL.ELEMENT_ARRAY_BUFFER, obj["indexBuffer"]], thisArg: glJs);
    gl.drawElements(WebGL.TRIANGLES, obj["indexBuffer"]["numItems"], WebGL.UNSIGNED_SHORT, 0);

    ctx.mvPop();
  }
}