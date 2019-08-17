import { fetchShader, createShader, createProgram } from "./utils.js"

async function main() {
  const vertexShaderSource = await fetchShader("vertex");
  const fragmentShaderSource = await fetchShader("fragment");

  var canvas = document.getElementById("c");
  var gl = canvas.getContext("webgl");
  if (!gl) {
    return;
  }
  var vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
  var fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource);
  var program = createProgram(gl, vertexShader, fragmentShader);

  var positionAttributeLocation = gl.getAttribLocation(program, "position");
  var positionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  var positions = [ -1, 1, 1, 1, 1, -1, 1, -1, -1, 1, -1, -1 ];
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);

  var size = 2;
  var type = gl.FLOAT;
  var normalize = false;
  var stride = 0;
  var offset = 0;
  gl.vertexAttribPointer(positionAttributeLocation, size, type, normalize, stride, offset);
  gl.clearColor(0, 0, 0, 0);
  gl.clear(gl.COLOR_BUFFER_BIT);
  var primitiveType = gl.TRIANGLES;
  var offset = 0;
  var count = 6;

  var cameraX = 1.0;
  var cameraY = 2.0;
  var cameraZ = 1.0;

  document.addEventListener('keydown', (event) => {
    if (event.defaultPrevented) {
      return;
    }
    var key = event.key || event.keyCode;

    if (key === 'w') {
      cameraZ += .1;
    }
    if (key === 'a') {
      cameraX -= .1;
    }
    if (key === 's') {
      cameraZ -= .1;
    }
    if (key === 'd') {
      cameraX += .1;
    }
    if (key === 'e') {
      cameraY += .1;
    }
    if (key === 'q') {
      cameraY -= .1;
    }
  });

  function render(time) {
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
  
    const uniforms = {
      time: time * 0.001,
      resolution: [gl.canvas.width, gl.canvas.height],
      cameraPosition: [cameraX, cameraY, cameraZ]
    };

    gl.useProgram(program);
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.enableVertexAttribArray(positionAttributeLocation);
    
    var positionUniformLocationTime = gl.getUniformLocation(program, "time");
    var positionUniformLocationResolution = gl.getUniformLocation(program, "resolution");
    var positionUniformLocationCameraPosition = gl.getUniformLocation(program, "camera");
    gl.uniform1f(positionUniformLocationTime, uniforms.time);
    gl.uniform2fv(positionUniformLocationResolution, uniforms.resolution);
    gl.uniform3fv(positionUniformLocationCameraPosition, uniforms.cameraPosition);

    gl.drawArrays(primitiveType, offset, count);

    requestAnimationFrame(render);
  }
  requestAnimationFrame(render);
}
main();