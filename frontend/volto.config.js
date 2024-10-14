const addons = ['volto-procergs-siteplone'];
const theme = '';

// Extend Webpack configuration
module.exports = (config) => {
  // Keep your existing addons and theme
  config.addons = addons;
  config.theme = theme;

  // Extend Webpack dev server configuration
  config.devServer = {
    port: 3000, // Force it to only use port 3000
    host: '0.0.0.0', // Allow access from any IP
    hot: true, // Enable hot reloading
    historyApiFallback: true, // Fallback for SPA routing
    client: {
      overlay: {
        warnings: false,
        errors: true,
      },
    },
    headers: {
      'Access-Control-Allow-Origin': '*', // Optional: Add CORS header if needed
    },
  };

  return config;
};
