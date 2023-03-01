import { config } from '@onflow/fcl';

config({
  'accessNode.api': 'https://rest-testnet.onflow.org', // Mainnet: "https://rest-mainnet.onflow.org"
  'discovery.wallet': 'https://fcl-discovery.onflow.org/testnet/authn', // Mainnet: "https://fcl-discovery.onflow.org/authn"
  // '0xProfile': '0xba1132bc08f82fe2', // The account address where the Profile smart contract lives on Testnet
  '0xGacha': '0x5a9a22c936e8866e',
  // '0xGacha': '0x82d2d6d5fb694351',
  // '0xGacha': '0x1b6ed9d2590cc03f',
  // '0xNonFungibleToken': '0x631e88ae7f1d7c20',
});
