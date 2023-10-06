const { ethers, Wallet, ContractFactory } = require('ethers');
const fs = require('fs');
require('dotenv').config();

const tokenArtifact = './artifacts/contracts/Token.sol/Token.json';
const poolArtifact = './artifacts/contracts/Pool.sol/KawaPool.json';

let token;
let pools;
let elonPool, shibPool, akitaPool, kishuPool, kawaPool;
let provider, wallet, connectedWallet;

if (process.env.NETWORK == 'testnet') {
	provider = ethers.getDefaultProvider(process.env.URL_TEST);
	pools = {
		elon: {
			token: '0x020b2db78e5603271f623C9A6bF73A3758293319',
			rewardRate: '2737030',
		},
		shib: {
			token: '0x37d3C98483745bc273B813c16922D76020C40BBA',
			rewardRate: '285705225',
		},
		akita: {
			token: '0xf4aF961bDf68c2c3fD6f9C87BF78852Ac7d7068f',
			rewardRate: '34246575',
		},
		kawa: {
			token: '0x073f6BF68De1f157508aa00baB5F6B2f544382bE',
			rewardRate: '95890410',
		},
	};
	token = '0xa3a5F9dC5FD2b7170Aaac1d749d609a3783bf383';
	elonPool = '0x398aDBe8e62eeA6e2ce70294457545D186C2ac14';
	shibPool = '0xf868eAC45EDf821CF7ccd05bcbE383B97855498F';
	akitaPool = '0x19F494d25e945e139940861A7859717346470D7D';
	kawaPool = '0x41cA4c2aE4B2a80E7f1955ff544be02c9da8ae37';
} else if (process.env.NETWORK == 'mainnet') {
	provider = ethers.getDefaultProvider(process.env.URL_MAIN);
	pools = {
		elon: {
			token: '0x761d38e5ddf6ccf6cf7c55759d5210750b5d60f3',
			rewardRate: '2737030',
		},
		shib: {
			token: '0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce',
			rewardRate: '285705225',
		},
		akita: {
			token: '0x3301ee63fb29f863f2333bd4466acb46cd8323e6',
			rewardRate: '34246575',
		},
		kishu: {
			token: '0xa2b4c0af19cc16a6cfacce81f192b024d625817d',
			rewardRate: '55428',
		},
		kawa: {
			token: '0x17a4ae8b1ea75d51ab0f2875b80452f7e34c272a',
			rewardRate: '95890410',
		},
	};

	token = '0xf2454D3C376f4244C8229b3d8498cee95eF40160';
	elonPool = '0x5DC2aA7BAFb6e984AC7c0c05e06630FC96A0a6f8';
	shibPool = '0xF9add0f05Dd89183f14f0c6339641246DCC6f2cd';
	akitaPool = '0xCB2dADc4F03909a4705029f5bbcf16E48677aC53';
	kishuPool = '0xB114B0c54Bf14900F30d5679474F716B52035aE5';
	kawaPool = '0x914522e40049D88db8225f285357Fb5fe97891EF';
}

wallet = Wallet.fromMnemonic(process.env.MNEMONIC);
connectedWallet = wallet.connect(provider);

const unpackArtifact = artifactPath => {
	let contractData = JSON.parse(fs.readFileSync(artifactPath));

	const contractBytecode = contractData['bytecode'];
	const contractABI = contractData['abi'];
	const constructorArgs = contractABI.filter(itm => {
		return itm.type == 'constructor';
	});

	let constructorStr;
	if (constructorArgs.length < 1) {
		constructorStr = ' -- No constructor arguments -- ';
	} else {
		constructorJSON = constructorArgs[0].inputs;
		constructorStr = JSON.stringify(
			constructorJSON.map(c => {
				return {
					name: c.name,
					type: c.type,
				};
			}),
		);
	}

	return {
		abi: contractABI,
		bytecode: contractBytecode,
		contractName: contractData.contractName,
		constructor: constructorStr,
	};
};

const deployContract = async (contractABI, contractBytecode, wallet, provider, args = []) => {
	const factory = new ContractFactory(contractABI, contractBytecode, wallet.connect(provider));
	return await factory.deploy(...args);
};

const deploy = async (artifactPath, args) => {
	try {
		let tokenUnpacked = unpackArtifact(artifactPath);
		console.log(`${tokenUnpacked.contractName} \n Constructor: ${tokenUnpacked.constructor}`);
		const token = await deployContract(tokenUnpacked.abi, tokenUnpacked.bytecode, wallet, provider, args);
		console.log(`⌛ Deploying ${tokenUnpacked.contractName}...`);

		await connectedWallet.provider.waitForTransaction(token.deployTransaction.hash);
		console.log(`✅ Deployed ${tokenUnpacked.contractName} to ${token.address}`);
		return token.address;
	} catch (err) {
		console.log('deploy ======>', err);
	}
};

const deployAll = async () => {
	if (!token) {
		try {
			token = await deploy(tokenArtifact, [
				'xKAWA',
				'xKAWA',
				'500000000000000000000000000',
				'0x93837577c98E01CFde883c23F64a0f608A70B90F',
			]);
		} catch (e) {
			return;
		}
	}

	if (!elonPool && pools && pools.elon) {
		console.log('Deploying Elon pool....');
		try {
			elonPool = await deploy(poolArtifact, [pools.elon.token, token, pools.elon.rewardRate]);
		} catch (e) {
			return;
		}
	}

	if (!shibPool && pools && pools.shib) {
		console.log('Deploying Shib pool....');
		try {
			shibPool = await deploy(poolArtifact, [pools.shib.token, token, pools.shib.rewardRate]);
		} catch (e) {
			return;
		}
	}

	if (!akitaPool && pools && pools.akita) {
		console.log('Deploying Akita pool....');
		try {
			akitaPool = await deploy(poolArtifact, [pools.akita.token, token, pools.akita.rewardRate]);
		} catch (e) {
			return;
		}
	}

	if (!kishuPool && pools && pools.kishu) {
		console.log('Deploying Kishu pool....');
		try {
			kishuPool = await deploy(poolArtifact, [pools.kishu.token, token, pools.kishu.rewardRate]);
		} catch (e) {
			return;
		}
	}

	if (!kawaPool && pools && pools.kawa) {
		console.log('Deploying Kawa pool....');
		try {
			kawaPool = await deploy(poolArtifact, [pools.kawa.token, token, pools.kawa.rewardRate]);
		} catch (e) {
			return;
		}
	}
};

deployAll();
