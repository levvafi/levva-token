import { task } from 'hardhat/config';
import { ContractTransactionReceipt, ethers, formatEther, toUtf8Bytes } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { VestingWalletFactory__factory } from '../typechain-types';

interface TaskArgs {
  signer: string;
}

// Example:
// npx hardhat --network holesky --config hardhat.config.ts create-vesting-wallets --signer <private-key>
task('create-vesting-wallets', 'create vesting wallets')
  .addParam<string>('signer', 'Private key of contracts creator')
  .setAction(async (taskArgs: TaskArgs, hre: HardhatRuntimeEnvironment) => {
    const provider = hre.ethers.provider;

    const startBlockNumber = await provider.getBlockNumber();
    const vestingWalletFactoryAddress = '0x40346BE3084c553Da2be699c55DF47C927f71272';
    const startTimestamp = 1732104000; // 2024-11-20
    const durationSeconds = 15552000; // 6 months
    const addresses = [
      '0x0521eF51E5Bb9930Bf0a8d9C0cFed3899A6deC93',
      '0x06602A51Ee06b28f9f4CFaDf5AB0e9cd6B97c931',
      '0x0774E64b4D33A2F922694d63ff4EDcd3Fee1Fb5b',
      '0x08866c443A2C71ff2fFA1FB63ff768d52f8f2c8b',
      '0x0999757972eE04D729Afc05FD21cb2aD911BC38d',
      '0x1039032c36D66711aC13BddD5ccf3a392Ca05AB4',
      '0x113c8B9cc435Ba839Dd46692acCdD57542d90C6e',
      '0x1233E68dEBE5f179AD72F0C1518489DCE7dA1449',
      '0x3896DE8d1a498881aC34F316E662D6e20236e577',
      '0x5bE1877cf14542DeC4565C0C830909A9C18622f5',
      '0x9242135C0fAdEf9c7e09037723E9EC237b07E6d4',
      '0xBa7475dD02c618c8cB87b871B2cf806DDcF36B9b',
      '0xEc5C5771cFe1Ec0beb1F3f612c785bE9a9B32D9C',
      '0xC30a527524bAc49a108813EE16b293A516C4d5e5',
    ];
    const vestingAmounts = [
      1000_000000000000000000n,
      200_000000000000000000n,
      300_000000000000000000n,
      400_000000000000000000n,
      500_000000000000000000n,
      600_000000000000000000n,
      700_000000000000000000n,
      800_000000000000000000n,
      900_000000000000000000n,
      1000_000000000000000000n,
      1100_000000000000000000n,
      1200_000000000000000000n,
      100_000000000000000000n,
      100_000000000000000000n,
    ];
    const amounts = [
      10_000000000000000000n,
      20_000000000000000000n,
      30_000000000000000000n,
      40_000000000000000000n,
      50_000000000000000000n,
      60_000000000000000000n,
      70_000000000000000000n,
      0n,
      0n,
      0n,
      0n,
      0n,
      10_000000000000000000n,
      10_000000000000000000n,
    ];
    //const tokenAddress = '0xaC3a8f70C421849Da72136DC7C8883984C2653B6'; //LVVA token
    //const tokenHolderAddress = '0x5e596657143656f22484ebD2D124dDF46C01efba'; // LVVA token holder for KOL vestings

    //DEBUG arguments
    const tokenAddress = '0x244141f247df46ce58cb81a101d0fb9787622126';
    const tokenHolderAddress = '0xAD70a0ab951780fF3397882fc5372db83dEb0606';

    console.log(`Current block number is ${startBlockNumber}\n\n`);

    let signer = new hre.ethers.Wallet(taskArgs.signer, provider);
    const balanceBefore = await signer.provider!.getBalance(signer);
    console.log(`Balance before: ${formatEther(balanceBefore)} Eth`);

    const vestingFactory = VestingWalletFactory__factory.connect(vestingWalletFactoryAddress, signer);
    const tx = await vestingFactory.createVestingWallets(
      addresses,
      vestingAmounts,
      amounts,
      tokenAddress,
      tokenHolderAddress,
      startTimestamp,
      durationSeconds
    );
    const txReceipt = await tx.wait();

    const balanceAfter = await signer.provider!.getBalance(signer);

    console.log(`Balance after: ${formatEther(balanceAfter)} Eth`);
    console.log(`Gas used for tx: ${txReceipt?.gasUsed} gas`);

    console.log(`Spent for tx: ${formatEther(balanceBefore - balanceAfter)} Eth`);
    console.log(`Done!`);
  });
