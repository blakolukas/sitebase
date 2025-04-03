import Login from './customizations/@plone-collective/volto-authomatic/components/Login/Login.jsx';

const applyConfig = (config) => {
  config.settings.isMultilingual = false;
  config.settings.supportedLanguages = ['pt-br'];
  config.settings.defaultLanguage = 'pt-br';

  config.addonRoutes.push({ path: '/login', component: Login });
  return config;
};

export default applyConfig;
