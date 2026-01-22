const http = require('http');
const { URL } = require('url');
const PORT = 3080;

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
};

const startupConfig = {
  appTitle: 'LibreChat',
  interface: {
    privacyPolicy: { externalUrl: '' },
    termsOfService: { externalUrl: '' },
    customWelcome: 'Welcome to LibreChat',
    heroTitle: 'LibreChat',
    heroDescription: 'Mock environment',
  },
  discordLoginEnabled: false,
  facebookLoginEnabled: false,
  githubLoginEnabled: false,
  googleLoginEnabled: false,
  openidLoginEnabled: false,
  appleLoginEnabled: false,
  samlLoginEnabled: false,
  openidLabel: '',
  openidImageUrl: '',
  openidAutoRedirect: false,
  samlLabel: '',
  samlImageUrl: '',
  ldap: { enabled: false },
  serverDomain: 'http://localhost:3080',
  emailLoginEnabled: true,
  registrationEnabled: true,
  socialLoginEnabled: false,
  passwordResetEnabled: true,
  emailEnabled: true,
  showBirthdayIcon: false,
  helpAndFaqURL: '',
  customFooter: '',
  modelSpecs: { list: [] },
  sharedLinksEnabled: false,
  publicSharedLinksEnabled: false,
  instanceProjectId: 'mock',
};

const banner = { enabled: false };

const user = {
  id: 'mock-user',
  name: 'Mock User',
  email: 'mock@example.com',
  image: '',
  role: 'user',
};

const endpoints = {
  all: {
    all: {
      type: 'all',
      model_map: ['gpt-4o'],
      label: 'All',
      name: 'all',
      iconURL: '',
      models: ['gpt-4o'],
    },
    openai: {
      type: 'openai',
      azure: false,
      model_map: ['gpt-4o'],
      label: 'OpenAI',
      name: 'openai',
      iconURL: '',
      models: ['gpt-4o'],
    },
  },
  model_map: {
    all: ['gpt-4o'],
    openai: ['gpt-4o'],
  },
  plugins: [],
};

const models = [
  { id: 'gpt-4o', endpoint: 'openai', displayName: 'gpt-4o', description: '' },
];

const convos = [];
const prompts = [];
const files = [];

http
  .createServer((req, res) => {
    const url = new URL(req.url, `http://localhost:${PORT}`);
    const path = url.pathname;

    const reply = (status, body) => {
      res.writeHead(status, headers);
      res.end(JSON.stringify(body));
    };

    if (path === '/api/config') return reply(200, startupConfig);
    if (path === '/api/banner') return reply(200, banner);
    if (path.startsWith('/api/auth/refresh')) return reply(200, { user, token: 'mock-token' });
    if (path === '/api/endpoints') return reply(200, endpoints);
    if (path === '/api/convos') return reply(200, convos);
    if (path === '/api/models') return reply(200, models);
    if (path === '/api/prompts/all') return reply(200, prompts);
    if (path === '/api/prompts/groups') return reply(200, prompts);
    if (path === '/api/files') return reply(200, files);
    if (path === '/api/files/speech/config/get') return reply(200, {});
    if (path === '/api/search/enable') return reply(200, { enabled: false });
    if (path === '/api/balance') return reply(200, { balance: 0 });
    if (path === '/api/roles/user') return reply(200, { roles: [] });
    if (path === '/api/user') return reply(200, user);

    return reply(404, { error: 'not found', path });
  })
  .listen(PORT, () => console.log(`[mock-api] listening on ${PORT}`));
