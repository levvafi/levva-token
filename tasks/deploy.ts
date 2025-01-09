import { task } from 'hardhat/config';
import { ContractTransactionReceipt, ethers, formatEther, toUtf8Bytes } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import {
  LevvaToken,
  LevvaToken__factory,
  Staking,
  Staking__factory,
  VestingWalletFactory,
  VestingWalletFactory__factory,
} from '../typechain-types';
import * as fs from 'fs';
import path from 'path';
import { CREATE_X_ABI, CREATE_X_ADDRESS } from './createX';

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

// Example:
// npx hardhat --network holesky --config hardhat.config.ts deploy-vesting-factory --signer <private-key>
task('deploy-vesting-factory', 'Deploy vesting factory')
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

    const contractId = 'VestingFactory';
    const factory = (await new VestingWalletFactory__factory(signer).deploy(signer)) as any as VestingWalletFactory;
    const deploymentTx = factory.deploymentTransaction()!;
    await factory.waitForDeployment();
    const txReceipt = await deploymentTx.wait();
    const txHash = deploymentTx.hash;

    const contractAddress = await factory.getAddress();

    const deploymentData = {
      [contractId]: {
        address: contractAddress,
        txHash,
        blockNumber: deploymentTx.blockNumber!,
      },
    };

    await saveDeploymentData(contractId, deploymentData, configDir);

    await verifyContract(hre, contractAddress, [signer.address]);

    const balanceAfter = await signer.provider!.getBalance(signer);
    console.log(`Balance after: ${formatEther(balanceAfter)} Eth`);
    console.log(`Gas used for deploy: ${txReceipt?.gasUsed} gas`);

    console.log(`Spent for deploy: ${formatEther(balanceBefore - balanceAfter)} Eth`);
    console.log(`Done!`);
  });

// Example:
// npx hardhat --network holesky --config hardhat.config.ts deploy-create3 --signer <private-key>
task('deploy-create3', 'Deploy token')
  .addParam<string>('signer', 'Private key of contracts creator')
  .setAction(async (taskArgs: DeployArgs, hre: HardhatRuntimeEnvironment) => {
    const provider = hre.ethers.provider;

    const tokenOwnerAddress = '0xB19ef98e52f1aB06E7f9E4Df7A8deF39665FaacC';
    //const tokenOwnerAddress = '0xAD70a0ab951780fF3397882fc5372db83dEb0606';

    const startBlockNumber = await provider.getBlockNumber();
    const networkName = hre.network.name;
    const configDir = `../deploy/${hre.network.name}`;

    console.log(`Deploy on network with CreateX factory"${networkName}"`);
    console.log(`Current block number is ${startBlockNumber}\n\n`);

    let signer = new hre.ethers.Wallet(taskArgs.signer, provider);

    const balanceBefore = await signer.provider!.getBalance(signer);
    console.log(`Balance before: ${formatEther(balanceBefore)} Eth`);

    const contractId = 'LevvaToken';
    const tokenByteCode = new LevvaToken__factory(signer).bytecode;

    const createXContract = await hre.ethers.getContractAt(CREATE_X_ABI, CREATE_X_ADDRESS, signer);

    const salt = '0x05950b4e68f103d5abef20364de219a247e59c2300e5266fd1d7f8fb0360eac7'; //ethers.keccak256(toUtf8Bytes('levva salt'));

    const create3Proxy = await createXContract['computeCreate3Address(bytes32,address)'](
      salt,
      '0x05950b4e68f103d5aBEf20364dE219a247e59C23'
    );
    console.log(`create3Proxy address is ${create3Proxy}`);

    const constructorArgs = hre.ethers.AbiCoder.defaultAbiCoder().encode(['address'], [tokenOwnerAddress]);
    const initCode = tokenByteCode.concat(constructorArgs.replace('0x', ''));
    const contractAddress = await createXContract['deployCreate3(bytes32,bytes)'].staticCall(salt, initCode);
    console.log(contractAddress);
    // const tx = await createXContract['deployCreate3(bytes32,bytes)'](salt, initCode);
    // const txReceipt: ContractTransactionReceipt = await tx.wait();
    // const txHash = txReceipt.hash;

    // console.log(`Contract address is ${contractAddress}`);

    // const deploymentData = {
    //   [contractId]: {
    //     address: contractAddress,
    //     txHash,
    //     blockNumber: startBlockNumber,
    //   },
    // };

    // await saveDeploymentData(deploymentData, configDir);

    // if (networkName !== 'hardhat') {
    //   await verifyContract(hre, contractAddress, []);
    // }

    // const balanceAfter = await signer.provider!.getBalance(signer);
    // console.log(`Balance after: ${formatEther(balanceAfter)} Eth`);
    // console.log(`Gas used for deploy: ${txReceipt?.gasUsed} gas`);

    // console.log(`Spent for deploy: ${formatEther(balanceBefore - balanceAfter)} Eth`);
    // console.log(`Done!`);
  });

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

async function verifyContract(hre: HardhatRuntimeEnvironment, address: string, constructorArguments: any[]) {
  const isDryRun = hre.config.networks.hardhat.forking !== undefined;
  if (!isDryRun) {
    console.log(`Verify contract ${address} with constructor arguments: ${constructorArguments}`);

    try {
      await hre.run('verify:verify', {
        address,
        constructorArguments,
      });
    } catch (e) {
      console.log(`Verify contract ${address} failed: ${e}`);
    }
  }
}
