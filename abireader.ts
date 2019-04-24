const fs = require('fs');
const path_contractservice = '../snarkfrontend/src/app/shared/contract89Seconds/contract.service.ts';
// const path_api = '../snarkbackend/src/config.ts';

const dictionary = [
	['private SnarkBaseABI =', './build/contracts/SnarkBase.json', 'abiSnarkBase: process.env.CONTRACT_ABI_SNARK_BASE'], 
	['private SnarkOfferABI =', './build/contracts/SnarkOffer.json', 'abiSnarkOffer: process.env.CONTRACT_ABI_SNARK_OFFER'],
	['private SnarkBidABI =', './build/contracts/SnarkBid.json', 'abiSnarkBid: process.env.CONTRACT_ABI_SNARK_BID'],
	['private SnarkLoanABI =', './build/contracts/SnarkLoan.json', 'abiSnarkLoan: process.env.CONTRACT_ABI_SNARK_LOAN'],
	['private SnarkERC721ABI =', './build/contracts/SnarkERC721.json', 'abiSnarkErc721: process.env.CONTRACT_ABI_SNARK_ERC721']
];

// CHANGE IN FRONTEND

if (fs.existsSync(path_contractservice)) {
	let new_buf = '';
	const buf = fs.readFileSync(path_contractservice).toString();
	buf.split(/\n/).forEach(function(line) {
		let tmp_line = line;
		for (let i = 0; i < dictionary.length; i++) {
			let key_line = dictionary[i][0];
			if (tmp_line.indexOf(key_line) != -1) {
				let path_to_file = dictionary[i][1];
				let contract = JSON.parse(fs.readFileSync(path_to_file));
				let abi = JSON.stringify(contract.abi);
				tmp_line = '  ' + key_line + ' ' + abi + ';';
			}
		}
		new_buf += tmp_line + '\n';
	});
	fs.writeFileSync(path_contractservice, new_buf);
} else {
	console.log('Can\'t find file');
}

// CHANGE IN BACKEND

// if (fs.existsSync(path_api)) {
// 	let new_buf = '';
// 	const buf = fs.readFileSync(path_api).toString();
// 	const arrayOfLines = buf.split(/\n/);
// 	for (let l = 0; l < arrayOfLines.length; l++) {
// 	  	let tmp_line = arrayOfLines[l];
// 		for (let i = 0; i < dictionary.length; i++) {
// 			let key_line = dictionary[i][2];
// 			if (tmp_line.indexOf(key_line) != -1) {
// 				tmp_line = '  ' + key_line + ' ||';
// 				new_buf += tmp_line + '\n';
// 				l++;
// 				tmp_line = arrayOfLines[l];
// 				let path_to_file = dictionary[i][1];
// 				let contract = JSON.parse(fs.readFileSync(path_to_file));
// 				let abi = JSON.stringify(contract.abi);
// 				// abi = abi.replace(',{"constant"', ',\n{"constant"');
// 				tmp_line = '  ' + abi + ',';
// 				break;
// 			} 
// 		}

// 		new_buf += tmp_line + '\n';
// 	}
// 	fs.writeFileSync(path_api, new_buf);
// } else {
// 	console.log('Can\'t find file');
// }


/*****  OLD CODE  *****/ 
// const fs = require('fs');
// const jsonfile = process.argv[process.argv.length - 1];
// const contract = JSON.parse(fs.readFileSync(jsonfile));
// console.log(JSON.stringify(contract.abi));
