import { task } from 'hardhat/config';
import { ContractTransactionReceipt, ethers, formatEther, toUtf8Bytes } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { VestingWalletFactory__factory } from '../typechain-types';

interface TaskArgs {
  signer: string;
}

task('create-vesting-wallets', 'create vesting wallets')
  .addParam<string>('signer', 'Private key of contracts creator')
  .setAction(async (taskArgs: TaskArgs, hre: HardhatRuntimeEnvironment) => {
    const provider = hre.ethers.provider;

    const startBlockNumber = await provider.getBlockNumber();
    const vestingWalletFactoryAddress = '';
    const startTimestamp = 0;
    const durationSeconds = 0;
    const addresses = [];
    const amounts = [];
    const tokenAddress = '';
    const tokenHolderAddress = '';

    console.log(`Current block number is ${startBlockNumber}\n\n`);

    let signer = new hre.ethers.Wallet(taskArgs.signer, provider);
    const balanceBefore = await signer.provider!.getBalance(signer);
    console.log(`Balance before: ${formatEther(balanceBefore)} Eth`);

    const vestingFactory = VestingWalletFactory__factory.connect(vestingWalletFactoryAddress, signer);
    const tx = await vestingFactory.createVestingWallets(
      addresses,
      amounts,
      tokenAddress,
      tokenHolderAddress,
      startTimestamp,
      durationSeconds
    );
    const txReceipt = await tx.wait();

    const balanceAfter = await signer.provider!.getBalance(signer);

    console.log(`Balance after: ${formatEther(balanceAfter)} Eth`);
    console.log(`Gas used for deploy: ${txReceipt?.gasUsed} gas`);

    console.log(`Spent for deploy: ${formatEther(balanceBefore - balanceAfter)} Eth`);
    console.log(`Done!`);
  });
