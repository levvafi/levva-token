import { task } from 'hardhat/config';
import { ContractTransactionReceipt, ethers, formatEther, Provider, toUtf8Bytes } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { LevvaToken, LevvaToken__factory, Staking, Staking__factory } from '../typechain-types';
import * as fs from 'fs';
import path from 'path';
import { CREATE_X_ABI, CREATE_X_ADDRESS } from './createX';
import { getSigner, SignerArgs, taskWithSigner, verifyContract } from './utils';

interface DeployArgs {
  signer: string;
}

interface DeploymentData {
  [key: string]: {
    address: string;
    txHash: string;
    blockNumber: number;
  };
}

// Example:
// npx hardhat --network hardhat --config hardhat.config.ts deploy-token --signer <private-key>
task('deploy', 'Deploy token')
  .addParam<string>('signer', 'Private key of contracts creator')
  .setAction(async (taskArgs: DeployArgs, hre: HardhatRuntimeEnvironment) => {
    const provider = hre.ethers.provider;

    const startBlockNumber = await provider.getBlockNumber();
    const networkName = hre.network.name;
    const configDir = `../deploy/${hre.network.name}`;

    console.log(`Deploy on network "${networkName}"`);
    console.log(`Current block number is ${startBlockNumber}\n\n`);

    let signer = new hre.ethers.Wallet(taskArgs.signer, provider);

    const balanceBefore = await signer.provider!.getBalance(signer);
    console.log(`Balance before: ${formatEther(balanceBefore)} Eth`);

    const owner = '0xea42f017a9D962019E36ce4D7d376D0421855b66'; // set owner address

    const contractId = 'LevvaToken';
    const token = (await new LevvaToken__factory(signer).deploy(owner)) as any as LevvaToken;
    const deploymentTx = token.deploymentTransaction()!;
    await token.waitForDeployment();
    const txReceipt = await deploymentTx.wait();
    const txHash = deploymentTx.hash;

    const contractAddress = await token.getAddress();

    const deploymentData = {
      [contractId]: {
        address: contractAddress,
        txHash,
        blockNumber: deploymentTx.blockNumber!,
      },
    };

    await saveDeploymentData(contractId, deploymentData, configDir);

    await verifyContract(hre, contractAddress, [owner]);

    const balanceAfter = await signer.provider!.getBalance(signer);
    console.log(`Balance after: ${formatEther(balanceAfter)} Eth`);
    console.log(`Gas used for deploy: ${txReceipt?.gasUsed} gas`);

    console.log(`Spent for deploy: ${formatEther(balanceBefore - balanceAfter)} Eth`);
    console.log(`Done!`);
  });

// Example: npx hardhat --network holesky --config hardhat.config.ts deploy-levva-staking --keystore <keystore-file>
taskWithSigner('deploy-levva-staking', 'Deploy Levva Staking smart contract').setAction(
  async (taskArgs: SignerArgs, hre: HardhatRuntimeEnvironment) => {
    const provider: Provider = hre.ethers.provider;
    const signer = await getSigner(taskArgs, provider);

    const startBlockNumber = await provider.getBlockNumber();
    const networkName = hre.network.name;
    const configDir = `../deploy/${hre.network.name}`;

    console.log(`Deploy on network "${networkName}"`);
    console.log(`Current block number is ${startBlockNumber}\n\n`);

    const balanceBefore = await provider.getBalance(signer);
    console.log(`Balance before: ${formatEther(balanceBefore)} Eth`);

    // Levva Staking arguments
    const TOKEN: string = '0x6243558a24CC6116aBE751f27E6d7Ede50ABFC76'; //LEVVA token
    const owner: string = '0xea42f017a9D962019E36ce4D7d376D0421855b66'; //owner
    const vault: string = '0xea42f017a9D962019E36ce4D7d376D0421855b66'; //vault

    // const APY: number = 120; // 120%
    // const LOCK: number = 2628000; // 1 month

    // const APY: number = 60;
    // const LOCK: number = 15768000; // 6 month

    const APY: number = 50;
    const LOCK: number = 31536000;

    const contractId = `LevvaStaking-${APY}-${LOCK}`;

    const staking = (await new Staking__factory(signer).deploy(TOKEN, owner, vault, APY, LOCK)) as any as Staking;
    const stakingAddress = await staking.getAddress();
    const stakingDeploymentTx = staking.deploymentTransaction()!;
    await staking.waitForDeployment();
    const stakingTxReceipt = await stakingDeploymentTx.wait();
    const stakingTxHash = stakingDeploymentTx.hash;

    await verifyContract(hre, stakingAddress, [TOKEN, owner, vault, APY, LOCK]);

    const deploymentData = {
      [contractId]: {
        address: await staking.getAddress(),
        txHash: stakingTxHash,
        blockNumber: stakingDeploymentTx.blockNumber!,
      },
    };

    await saveDeploymentData(contractId, deploymentData, configDir);

    const balanceAfter = await signer.provider!.getBalance(signer);
    console.log(`Balance after: ${formatEther(balanceAfter)} Eth`);
    console.log(`Gas used for deploy: ${stakingTxReceipt?.gasUsed} gas`);

    console.log(`Spent for deploy: ${formatEther(balanceBefore - balanceAfter)} Eth`);
    console.log(`Done!`);
  }
);

// Example:
// npx hardhat --network holesky --config hardhat.config.ts deploy-open-staking --signer <private-key>
task('deploy-open-staking', 'Deploy open staking contract')
  .addParam<string>('signer', 'Private key of contracts creator')
  .setAction(async (taskArgs: DeployArgs, hre: HardhatRuntimeEnvironment) => {
    const provider = hre.ethers.provider;

    const startBlockNumber = await provider.getBlockNumber();
    const networkName = hre.network.name;
    const configDir = `../deploy/${hre.network.name}`;

    console.log(`Deploy on network "${networkName}"`);
    console.log(`Current block number is ${startBlockNumber}\n\n`);

    let signer = new hre.ethers.Wallet(taskArgs.signer, provider);

    const balanceBefore = await signer.provider!.getBalance(signer);
    console.log(`Balance before: ${formatEther(balanceBefore)} Eth`);

    // Open Staking arguments
    const APY: number = 0; // 0%
    const LOCK: number = 31_536_000; // 365 * 24 * 60 * 60 - 1 year
    const TOKEN: string = '0x4123a133ae3c521FD134D7b13A2dEC35b56c2463'; //OPEN token
    const owner: string = '0xea42f017a9D962019E36ce4D7d376D0421855b66'; //LVVA owner
    const vault: string = '0x4fBc79d384235e59574A2ebB6c721E4B939Ce188'; // prev open staking parameter

    // const TOKEN: string = '0xaC3a8f70C421849Da72136DC7C8883984C2653B6'; // LVVA token
    // const owner: string = '0xea42f017a9D962019E36ce4D7d376D0421855b66'; // LVVA owner
    // const vault: string = '0x8dD5C9A136E1AbD616620ab4EFdFBfeCfc28b180'; // Levva Treasury

    // LevvaStaking 1 month
    // const contractId = 'LevvaStaking-1month';
    // const APY: number = 10; // 10%
    // const LOCK: number = 31_536_000; // 30 * 24 * 60 * 60 - 1 month

    // LevvaStaking 6 month
    // const contractId = 'LevvaStaking-6months';
    // const APY: number = 30; // 30%
    // const LOCK: number = 15_552_000; // 6 * 30 * 24 * 60 * 60 - 6 months

    // LevvaStaking 1 year
    // const contractId = 'LevvaStaking-1year';
    // const APY: number = 50; // 50%
    // const LOCK: number = 31_536_000; // 365 * 24 * 60 * 60 - 1 year

    const contractId = 'OpenStaking';
    const staking = (await new Staking__factory(signer).deploy(TOKEN, owner, vault, APY, LOCK, {
      gasLimit: 2_000_000,
      gasPrice: 11_000_000_000,
    })) as any as Staking;
    const stakingAddress = await staking.getAddress();
    const stakingDeploymentTx = staking.deploymentTransaction()!;
    await staking.waitForDeployment();
    const stakingTxReceipt = await stakingDeploymentTx.wait();
    const stakingTxHash = stakingDeploymentTx.hash;

    await verifyContract(hre, stakingAddress, [TOKEN, owner, vault, APY, LOCK]);

    const deploymentData = {
      [contractId]: {
        address: await staking.getAddress(),
        txHash: stakingTxHash,
        blockNumber: stakingDeploymentTx.blockNumber!,
      },
    };

    await saveDeploymentData(contractId, deploymentData, configDir);

    const balanceAfter = await signer.provider!.getBalance(signer);
    console.log(`Balance after: ${formatEther(balanceAfter)} Eth`);
    console.log(`Gas used for deploy: ${stakingTxReceipt?.gasUsed} gas`);

    console.log(`Spent for deploy: ${formatEther(balanceBefore - balanceAfter)} Eth`);
    console.log(`Done!`);
  });

async function saveDeploymentData(
  contractId: string,
  deploymentData: DeploymentData,
  configDir: string
): Promise<void> {
  const date = new Date();
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  const filename = configDir + `/deployment-${contractId}-${year}-${month}-${day}.json`;
  const data = JSON.stringify(deploymentData, null, 2) + `\n`;
  const resolvedPath = path.resolve(__dirname, filename);
  fs.writeFileSync(resolvedPath, data, { flag: 'wx' });
  console.log(`\nDeployment data saved: ${resolvedPath}`);
}
