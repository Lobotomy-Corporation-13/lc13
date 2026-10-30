/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

const createBabelConfig = options => {
  const { mode, presets = [], plugins = [] } = options;
  return {
    presets: [
      ['@babel/preset-env', {
        modules: 'commonjs',
        useBuiltIns: 'entry',
        corejs: '3.8',
        spec: false,
        loose: true,
        targets: [],
      }],
      ['@babel/preset-react', {
        runtime: 'automatic',
      }],
      ...presets,
    ],
    plugins: [
      // Production only: in development it would also strip React's own
      // warnings (keys, unknown props, style names) from node_modules.
      ...(mode === 'production' ? ['babel-plugin-transform-remove-console'] : []),
      'common/string.babel-plugin.cjs',
      ...plugins,
    ],
  };
};

module.exports = (api) => {
  api.cache(true);
  const mode = process.env.NODE_ENV;
  return createBabelConfig({ mode });
};

module.exports.createBabelConfig = createBabelConfig;
