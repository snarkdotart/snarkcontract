const fs = require('fs');
const path_env_prod = '../snarkfrontend/src/environments/environment.prod.ts';
const path_env = '../snarkfrontend/src/environments/environment.ts';
// const path_api = '../snarkbackend/src/config.ts';

const dictionary = [
	['CONTRACT_SNARKBASE_ADDRESS', './build/contracts/SnarkBase.json', 'addressSnarkBase: process.env.CONTRACT_ADDRESS_SNARK_BASE'], 
	['CONTRACT_SNARKOFFERBID_ADDRESS', './build/contracts/SnarkOfferBid.json', 'addressSnarkOfferBid: process.env.CONTRACT_ADDRESS_SNARK_OFFER_BID'],
	['CONTRACT_SNARKLOAN_ADDRESS', './build/contracts/SnarkLoan.json', 'addressSnarkLoan: process.env.CONTRACT_ADDRESS_SNARK_LOAN'],
	['CONTRACT_SNARKLOANEXT_ADDRESS', './build/contracts/SnarkLoanExt.json', 'addressSnarkLoan: process.env.CONTRACT_ADDRESS_SNARK_LOAN_EXT'],
	['CONTRACT_SNARKERC721_ADDRESS', './build/contracts/SnarkERC721.json', 'addressSnarkErc721: process.env.CONTRACT_ADDRESS_SNARK_ERC721']
];

const network_number = process.argv[process.argv.length - 1];

/*
for (let i = 0; i < dictionary.length; i++) {
	let key_line = dictionary[i][0];
	let path_to_file = dictionary[i][1];
	let contract = JSON.parse(fs.readFileSync(path_to_file));
	let addr = JSON.stringify(contract.networks[3].address);
	console.log(key_line, ': ', addr);
}
*/

// FRONTEND - DEVELOPMENT ENVIRONMENT

if (fs.existsSync(path_env)) {
	let new_buf = '';
	const buf = fs.readFileSync(path_env).toString();
	buf.split(/\n/).forEach(function(line) {
		let tmp_line = line;
		for (let i = 0; i < dictionary.length; i++) {
			let key_line = dictionary[i][0];
			if (tmp_line.indexOf(key_line) != -1) {
				let path_to_file = dictionary[i][1];
				let contract = JSON.parse(fs.readFileSync(path_to_file));
				let addr = JSON.stringify(contract.networks[network_number].address);
				tmp_line = '  ' + key_line + ': ' + addr + ',';
			}
		}
		new_buf += tmp_line + '\n';
	});
	fs.writeFileSync(path_env, new_buf);
} else {
	console.log('Can\'t find file');
}

// FRONTEND - PRODUCTION ENVIRONMENT

if (fs.existsSync(path_env_prod)) {
	let new_buf = '';
	const buf = fs.readFileSync(path_env_prod).toString();
	buf.split(/\n/).forEach(function(line) {
		let tmp_line = line;
		for (let i = 0; i < dictionary.length; i++) {
			let key_line = dictionary[i][0];
			if (tmp_line.indexOf(key_line) != -1) {
				let path_to_file = dictionary[i][1];
				let contract = JSON.parse(fs.readFileSync(path_to_file));
				let addr = JSON.stringify(contract.networks[network_number].address);
				tmp_line = '  ' + key_line + ': ' + addr + ',';
			}
		}
		new_buf += tmp_line + '\n';
	});
	fs.writeFileSync(path_env_prod, new_buf);
} else {
	console.log('Can\'t find file');
}

// BACKEND

// if (fs.existsSync(path_api)) {
// 	let new_buf = '';
// 	const buf = fs.readFileSync(path_api).toString();
// 	buf.split(/\n/).forEach(function(line) {
// 		let tmp_line = line;
// 		for (let i = 0; i < dictionary.length; i++) {
// 			let key_line = dictionary[i][2];
// 			if (tmp_line.indexOf(key_line) != -1) {
// 				let path_to_file = dictionary[i][1];
// 				let contract = JSON.parse(fs.readFileSync(path_to_file));
// 				let addr = JSON.stringify(contract.networks[network_number].address);
// 				tmp_line = '  ' + key_line + ' || ' + addr + ',';
// 			}
// 		}
// 		new_buf += tmp_line + '\n';
// 	});
// 	fs.writeFileSync(path_api, new_buf);
// } else {
// 	console.log('Can\'t find file');
// }
