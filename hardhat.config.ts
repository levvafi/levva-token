import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-contract-sizer';
import * as defaultConfig from './hardhat.common';
import './tasks/deploy';
import './tasks/vesting';

const config = {
  ...defaultConfig.default,
  networks: {
    ethereum: {
      url: 'https://rpc.ankr.com/eth',
    },
    holesky: {
      url: 'https://1rpc.io/holesky',
    },
  },
};

export default config;
