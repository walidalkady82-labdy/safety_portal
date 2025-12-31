// In web/build.js
const fs = require('fs');
const path = require('path');

module.exports = {
  "build": (args) => {
    // Add Emscripten build arguments here.
    // e.g. args.push("-s", "WASM=1");
    // See: https://emscripten.org/docs/compiling/Building-Projects.html#building-projects-with-emcc
    // For all available settings, see: https://github.com/emscripten-core/emscripten/blob/main/src/settings.js
    
    // The following arguments are required to enable dynamic linking for tflite_web.
    args.push("-s", "MAIN_MODULE=2");
    args.push("-s", "ALLOW_MEMORY_GROWTH=1");
    
    return args;
  }
};
