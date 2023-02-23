# NFT Gacha web

## init

```
npx create-next-app@latest nft-gacha-web
```

## FCL

```
npm install @onflow/fcl @onflow/types  --save
```

## tailwind, prettier

```
npm install -D prettier
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
npm install -D prettier-plugin-tailwindcss
```

## .eslintrc.json

警告出るので"next/babel"を追加
```
{
  "extends": ["next/core-web-vitals", "next/babel"]
}
```

## config.js

flowと対話するための設定ファイルをflow/config.jsで作成する。

```js
import { config } from "@onflow/fcl";

config({
  "accessNode.api": "https://rest-testnet.onflow.org", // Mainnet: "https://rest-mainnet.onflow.org"
  "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn" // Mainnet: "https://fcl-discovery.onflow.org/authn"
})
```