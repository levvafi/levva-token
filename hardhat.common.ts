import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-contract-sizer';
import { config as dotEnvConfig } from 'dotenv';

dotEnvConfig();

const config: HardhatUserConfig & { contractSizer: any } = {
  solidity: {
    compilers: [
      {
        version: '0.8.27',
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 1000000,
          },
        },
      },
    ],
  },
  networks: {
    ethereum: {
      url: 'https://rpc.ankr.com/eth',
    },
    holesky: {
      url: 'https://1rpc.io/holesky',
    },
  },
  etherscan: {
    apiKey: process.env.API_KEY,
  },
  mocha: {
    timeout: 2_000_000,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: false,
    only: ['Levva', 'Vesting'],
    except: ['Mock', 'Test'],
  },
  sourcify: {
    enabled: false,
  },
};

export default config;