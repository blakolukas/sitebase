module.exports = {
  modifyWebpackConfig({ env: { target, dev }, webpackConfig, paths }) {
    if (target === 'web' && dev) {
      // Modify the webpack devServer settings for development mode
      webpackConfig.devServer = {
        // Configure the dev server to use port 3000
        port: 3000,
        // Host is set to 0.0.0.0 to allow access from external machines
        host: '0.0.0.0',
        // Enable hot reloading
        hot: true,
        // Serve content from the public directory
        static: paths.appPublic,
        // Fallback to index.html for 404s
        historyApiFallback: true,
        // Allow connections from localhost and all network interfaces
        allowedHosts: 'all',
      };
    }
    return webpackConfig;
  },
};
