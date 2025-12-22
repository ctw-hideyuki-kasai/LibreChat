# Storybook導入手順（git worktree使用）

このドキュメントでは、git worktreeを使って分離したブランチでStorybookを導入し、`AuthLayout`コンポーネントを確認する手順を説明します。

## 前提条件

- Gitがインストールされていること
- Node.jsとnpmがインストールされていること
- 現在のリポジトリがクリーンな状態であること（未コミットの変更がないこと）

## 手順

### 1. git worktreeで分離ブランチを作成

```bash
# 現在のディレクトリから移動（必要に応じて）
cd ..

# git worktreeで新しいブランチとディレクトリを作成
# 例: storybook-authlayout というブランチを ../LibreChat-storybook に作成
git worktree add ../LibreChat-storybook -b storybook-authlayout

# 新しいworktreeディレクトリに移動
cd ../LibreChat-storybook
```

### 2. Storybookをインストール

```bash
# clientディレクトリに移動
cd client

# Storybookを初期化（Vite + Reactを選択）
npx storybook@latest init --yes

# または、手動でインストールする場合
npm install --save-dev @storybook/react @storybook/react-vite @storybook/addon-essentials @storybook/addon-interactions @storybook/test
```

### 3. Storybook設定ファイルの作成

`client/.storybook/main.ts` を作成（または既存のファイルを編集）：

```typescript
import type { StorybookConfig } from '@storybook/react-vite';
import { mergeConfig } from 'vite';
import path from 'path';

const config: StorybookConfig = {
  stories: ['../src/**/*.stories.@(js|jsx|ts|tsx|mdx)'],
  addons: [
    '@storybook/addon-essentials',
    '@storybook/addon-interactions',
  ],
  framework: {
    name: '@storybook/react-vite',
    options: {},
  },
  async viteFinal(config) {
    return mergeConfig(config, {
      resolve: {
        alias: {
          '~': path.resolve(__dirname, '../src/'),
          $fonts: path.resolve(__dirname, '../public/fonts'),
        },
      },
      // 既存のVite設定と互換性を保つ
      define: {
        'process.env': {},
      },
    });
  },
};

export default config;
```

### 4. Storybookのプレビュー設定

`client/.storybook/preview.ts` を作成（または既存のファイルを編集）：

```typescript
import type { Preview } from '@storybook/react';
import '../src/index.css'; // Tailwind CSSのインポート

const preview: Preview = {
  parameters: {
    actions: { argTypesRegex: '^on[A-Z].*' },
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/,
      },
    },
    // ダークモード対応
    backgrounds: {
      default: 'light',
      values: [
        {
          name: 'light',
          value: '#ffffff',
        },
        {
          name: 'dark',
          value: '#111827',
        },
      ],
    },
  },
  // グローバルデコレーター（必要に応じて）
  decorators: [
    (Story) => (
      <div className="min-h-screen bg-white dark:bg-gray-900">
        <Story />
      </div>
    ),
  ],
};

export default preview;
```

### 5. AuthLayout用のStoryファイルを作成

`client/src/components/Auth/AuthLayout.stories.tsx` を作成：

```typescript
import type { Meta, StoryObj } from '@storybook/react';
import AuthLayout from './AuthLayout';
import type { TStartupConfig } from 'librechat-data-provider';

// モックデータ
const mockStartupConfig: TStartupConfig = {
  appTitle: 'LibreChat',
  interface: {
    privacyPolicy: { externalUrl: '' },
    termsOfService: { externalUrl: '' },
  },
  // 必要に応じて他のプロパティを追加
} as TStartupConfig;

const meta: Meta<typeof AuthLayout> = {
  title: 'Auth/AuthLayout',
  component: AuthLayout,
  parameters: {
    layout: 'fullscreen',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof AuthLayout>;

// 基本のログイン画面
export const Login: Story = {
  args: {
    header: 'ログイン',
    isFetching: false,
    startupConfig: mockStartupConfig,
    startupConfigError: null,
    pathname: '/login',
    error: null,
    children: (
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">メールアドレス</label>
          <input
            type="email"
            className="w-full px-3 py-2 border rounded-md"
            placeholder="email@example.com"
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">パスワード</label>
          <input
            type="password"
            className="w-full px-3 py-2 border rounded-md"
            placeholder="••••••••"
          />
        </div>
        <button className="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
          ログイン
        </button>
      </div>
    ),
  },
};

// ローディング状態
export const Loading: Story = {
  args: {
    ...Login.args,
    isFetching: true,
  },
};

// エラー状態
export const WithError: Story = {
  args: {
    ...Login.args,
    error: 'com_auth_error_invalid_credentials',
  },
};

// リセットトークンエラー
export const ResetTokenError: Story = {
  args: {
    ...Login.args,
    pathname: '/reset-password',
    error: 'com_auth_error_invalid_reset_token',
  },
};

// サーバーエラー
export const ServerError: Story = {
  args: {
    ...Login.args,
    startupConfigError: new Error('Server connection failed'),
  },
};

// 登録画面
export const Register: Story = {
  args: {
    ...Login.args,
    header: '新規登録',
    pathname: '/register',
    children: (
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">ユーザー名</label>
          <input
            type="text"
            className="w-full px-3 py-2 border rounded-md"
            placeholder="username"
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">メールアドレス</label>
          <input
            type="email"
            className="w-full px-3 py-2 border rounded-md"
            placeholder="email@example.com"
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">パスワード</label>
          <input
            type="password"
            className="w-full px-3 py-2 border rounded-md"
            placeholder="••••••••"
          />
        </div>
        <button className="w-full px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700">
          登録
        </button>
      </div>
    ),
  },
};
```

### 6. 依存関係のモック設定（必要に応じて）

`AuthLayout`が依存するコンポーネントやフックが動作するように、必要に応じてモックを作成します。

`client/src/components/Auth/.storybook/mocks.ts` を作成（オプション）：

```typescript
// useLocalizeフックのモック
export const mockLocalize = (key: string) => {
  const translations: Record<string, string> = {
    'com_auth_error_login_server': 'サーバー接続エラーが発生しました',
    'com_auth_error_invalid_reset_token': '無効なリセットトークンです',
    'com_auth_click_here': 'ここをクリック',
    'com_auth_to_try_again': 'して再試行してください',
    'com_auth_error_invalid_credentials': 'メールアドレスまたはパスワードが正しくありません',
  };
  return translations[key] || key;
};
```

### 7. package.jsonにStorybookスクリプトを追加

`client/package.json` の `scripts` セクションに追加：

```json
{
  "scripts": {
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build"
  }
}
```

### 8. Storybookを起動

```bash
# clientディレクトリで実行
npm run storybook
```

ブラウザで `http://localhost:6006` にアクセスして、`AuthLayout`コンポーネントの各種状態を確認できます。

## 注意事項

1. **依存パッケージ**: `@librechat/client` や `librechat-data-provider` などの内部パッケージが正しく解決されるように、必要に応じて追加の設定が必要です。

2. **アセットファイル**: ロゴ画像などのアセットは `client/public/assets/` に配置されている必要があります。Storybookでは `public` ディレクトリが自動的に参照されます。

3. **Tailwind CSS**: `client/src/index.css` が正しくインポートされていることを確認してください。

4. **i18n設定**: `useLocalize` フックが動作するように、必要に応じてi18nの設定をモックする必要があります。

## worktreeの削除（作業完了後）

作業が完了したら、worktreeを削除できます：

```bash
# 元のリポジトリディレクトリに戻る
cd ../LibreChat

# worktreeを削除
git worktree remove ../LibreChat-storybook

# ブランチも削除する場合
git branch -D storybook-authlayout
```

## トラブルシューティング

### パスエイリアスが解決されない場合

`.storybook/main.ts` の `viteFinal` でパスエイリアスの設定を確認してください。

### スタイルが適用されない場合

`.storybook/preview.ts` でCSSファイルが正しくインポートされているか確認してください。

### コンポーネントの依存関係エラー

必要なコンポーネント（`ErrorMessage`, `SocialLoginRender`, `BlinkAnimation`, `Banner`, `Footer`）が正しくインポートできることを確認してください。必要に応じて、これらのコンポーネントもStorybookで確認できるようにStoryファイルを作成してください。

