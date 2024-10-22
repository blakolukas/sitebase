module.exports = {
  modifyWebpackConfig(opts) {
    const config = opts.webpackConfig;

    if (opts.env.dev) {
      config.devServer = {
        port: 3000,           // Set the port to 3000
        host: "0.0.0.0",      // Make the server accessible externally
        compress: true,       // Enable gzip compression
        hot: true,            // Enable hot module replacement
        historyApiFallback: true, // Ensure correct fallback for single-page apps
        headers: {
          "Access-Control-Allow-Origin": "*", // Set CORS headers if needed
        },
        static: {
          directory: "/opt/app-root/src/core/packages/volto/public", // Serve static files
        },
        client: {
          overlay: true, // Show overlay for errors
        },
      };
    }

    return config;
  },
};
