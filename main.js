import { fetchShader } from "./utils.js"

async function main() {
  const vertexShader = await fetchShader("vertex");
  const fragmentShader = await fetchShader("fragment");

  const body = document.getElementsByTagName("BODY")[0];
  const vElem = document.createElement("script");
  vElem.id = "vs";
  vElem.type = "notjs"
  vElem.append(vertexShader);
  body.appendChild(vElem);
  const fElem = document.createElement("script");
  fElem.id = "fs";
  fElem.type = "notjs"
  fElem.append(fragmentShader);
  body.appendChild(fElem);

  const gl = document.querySelector("#c").getContext("webgl");
  const programInfo = twgl.createProgramInfo(gl, ["vs", "fs"]);

  const arrays = {
    position: [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
  };
  const bufferInfo = twgl.createBufferInfoFromArrays(gl, arrays);

  var cameraX = 8.0;
  var cameraY = 5.0;
  var cameraZ = 7.0;


  document.addEventListener('keydown', (event) => {
    if (event.defaultPrevented) {
      return;
    }
    var key = event.key || event.keyCode;

    if (key === 'w') {
      cameraY += 1;
    }
    if (key === 'a') {
      cameraX -= 1;
    }
    if (key === 's') {
      cameraY -= 1;
    }
    if (key === 'd') {
      cameraX += 1;
    }
  });

  function render(time) {
    twgl.resizeCanvasToDisplaySize(gl.canvas);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

    const uniforms = {
      time: time * 0.001,
      resolution: [gl.canvas.width, gl.canvas.height],
      cameraPosition: [cameraX, cameraY, cameraZ]
    };

    gl.useProgram(programInfo.program);
    twgl.setBuffersAndAttributes(gl, programInfo, bufferInfo);
    twgl.setUniforms(programInfo, uniforms);
    twgl.drawBufferInfo(gl, bufferInfo);

    requestAnimationFrame(render);
  }
  requestAnimationFrame(render);
}
main();