import { prompts } from 'prompts';
import { task } from 'hardhat/config';
import { ConfigurableTaskDefinition, HardhatRuntimeEnvironment } from 'hardhat/types';
import { ethers, formatEther, parseEther, Signer } from 'ethers';
import * as fs from 'fs';

export interface SignerArgs {
  privateKey?: string;
  keystore?: string;
  keystorePassword?: string;
}

export interface DeployArgs extends SignerArgs {
  networkName: string;
  impersonateSigner?: string;
}

export const taskWithSigner = (name: string, description?: string): ConfigurableTaskDefinition =>
  task(name, description)
    .addOptionalParam<string>('privateKey', 'Private key of contracts creator')
    .addOptionalParam<string>('keystore', 'Keystore file path')
    .addOptionalParam<string>('keystorePassword', 'Keystore file password');

export const deployTask = (name: string, description?: string): ConfigurableTaskDefinition =>
  taskWithSigner(name, description)
    .addParam<string>('networkName', 'Network name')
    .addOptionalParam<string>('impersonateSigner', 'Impersonate address for dry-run');

const readSensitiveData = async (label: string): Promise<string> => {
  const response = await prompts.invisible({
    type: 'invisible',
    name: 'result',
    message: label,
  });
  return response as string;
};

export async function getSigner(taskArgs: SignerArgs, provider?: ethers.Provider | null): Promise<ethers.Wallet> {
  let signer: ethers.Wallet;

  if (taskArgs.privateKey) {
    console.warn('\n!!! Using private key in plain text is not recommended\n');

    signer = new ethers.Wallet(taskArgs.privateKey);
  } else if (taskArgs.keystore) {
    let keystorePassword = '';

    if (taskArgs.keystorePassword) {
      console.warn('\n!!! Use interactive mode to enter keystore password\n');

      keystorePassword = taskArgs.keystorePassword;
    } else {
      keystorePassword = await readSensitiveData('Enter keystore password');
    }
    const jsonKeystore = fs.readFileSync(taskArgs.keystore, 'utf8');

    const wallet = ethers.Wallet.fromEncryptedJsonSync(jsonKeystore, keystorePassword) as ethers.Wallet;
    if (!wallet) {
      throw new Error('Could not create wallet from keystore');
    }

    signer = provider ? wallet.connect(provider) : wallet;
  } else {
    const privateKey = await readSensitiveData('Enter signer private key');
    signer = new ethers.Wallet(privateKey, provider);
  }

  return signer;
}

export function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function verifyContract(hre: HardhatRuntimeEnvironment, address: string, constructorArguments: any[]) {
  const isDryRun = hre.config.networks.hardhat.forking !== undefined;
  if (isDryRun) return;

  await delay(25_000);

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
