const { getDefaultConfig } = require('expo/metro-config');

/** @type {import('expo/metro-config').MetroConfig} */
const config = getDefaultConfig(__dirname);

// Permite a Metro cargar los binarios de SQLite (WebAssembly) en la versión web
config.resolver.assetExts.push('wasm');

module.exports = config;
