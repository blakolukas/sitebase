module.exports = {
  modifyWebpackConfig({ env: { target, dev }, webpackConfig }) {
    // Only apply this modification for development (dev) and client-side (web)
    if (dev && target === 'web') {
      // Override the devServer configuration
      webpackConfig.devServer = {
        ...webpackConfig.devServer, // Preserve existing configuration
        port: 3000, // Force webpack-dev-server to use port 3000
        host: '0.0.0.0', // Listen on all network interfaces
        hot: true, // Enable hot module reloading
        historyApiFallback: true, // SPA fallback for routing
        client: {
          overlay: {
            warnings: false,
            errors: true,
          },
        },
        headers: {
          'Access-Control-Allow-Origin': '*', // Optional: CORS if necessary
        },
      };
    }
    return webpackConfig;
  },
};
