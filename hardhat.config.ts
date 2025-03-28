import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-contract-sizer';
import * as defaultConfig from './hardhat.common';
import './tasks/deploy';

const config = {
  ...defaultConfig.default,
  networks: {
    ethereum: {
      url: 'https://rpc.ankr.com/eth',
    },
    holesky: {
      url: 'https://1rpc.io/holesky',
    },
    sepolia: {
      url: 'https://rpc.ankr.com/eth_sepolia',
    },
  },
};

export default config;
