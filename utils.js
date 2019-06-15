export async function fetchShader(shaderType) {
    return new Promise(async (resolve, reject) => {
        const response = await fetch(`./${shaderType}.glsl`);
        const shader = await response.text();
        resolve(shader);
    })
}