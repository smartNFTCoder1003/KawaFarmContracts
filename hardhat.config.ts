import { task } from 'hardhat/config';
import './tasks/compile';
import '@nomiclabs/hardhat-waffle';
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('hardhat-contract-sizer');
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (args, hre) => {
	const accounts = await hre.ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

const MNEMONIC_DV_TEST_WALLET = process.env.MNEMONIC;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
	solidity: {
		version: '0.6.12',
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	networks: {
		testnet: {
			url: 'https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
			chainId: 4,
			gas: 40000000,
			blockGasLimit: 9500000,
			gasPrice: 20000000000,
			accounts: { mnemonic: MNEMONIC_DV_TEST_WALLET },
		},
		mainnet: {
			url: 'https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
			chainId: 1,
			gas: 40000000,
			blockGasLimit: 9500000,
			gasPrice: 20000000000,
			accounts: { mnemonic: MNEMONIC_DV_TEST_WALLET },
		},
	},
};
