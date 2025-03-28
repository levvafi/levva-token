import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-contract-sizer';
import * as defaultConfig from './hardhat.common';
import { config as dotEnvConfig } from 'dotenv';
import './tasks/deploy';

dotEnvConfig();

const config = {
  ...defaultConfig.default,
  networks: {
    ethereum: {
      url: process.env.ETH_RPC_URL,
    },
    holesky: {
      url: process.env.HOLESKY_RPC_URL,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
    },
  },
};

export default config;
