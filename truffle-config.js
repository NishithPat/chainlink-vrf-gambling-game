require('dotenv').config();
const path = require("path");

const HDWalletProvider = require('@truffle/hdwallet-provider');

const fs = require('fs');
const mnemonic = process.env.MNEMONIC;

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    develop: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    kovan: {
      provider: () => new HDWalletProvider(mnemonic, `wss://kovan.infura.io/ws/v3/${process.env.INFURA_KEY}`),
      network_id: 42,
      gas: 5500000,
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
  },
  plugins: ['truffle-plugin-verify'],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },
  compilers: {
    solc: {
      version: ">=0.6.0 <0.9.0",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};
