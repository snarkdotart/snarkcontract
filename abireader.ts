const fs = require('fs');
const path_contractservice = '../snarkfrontend/src/app/shared/contract/contract.service.ts';
const dictionary = [
	['private SnarkBaseABI =', './build/contracts/SnarkBase.json', 'abiSnarkBase: process.env.CONTRACT_ABI_SNARK_BASE'], 
	['private SnarkOfferBidABI =', './build/contracts/SnarkOfferBid.json', 'abiSnarkOfferBid: process.env.CONTRACT_ABI_SNARK_OFFER_BID'],
	['private SnarkLoanABI =', './build/contracts/SnarkLoan.json', 'abiSnarkLoan: process.env.CONTRACT_ABI_SNARK_LOAN'],
	['private SnarkERC721ABI =', './build/contracts/SnarkERC721.json', 'abiSnarkErc721: process.env.CONTRACT_ABI_SNARK_ERC721']
];

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

/*****  OLD CODE  *****/ 
// const fs = require('fs');
// const jsonfile = process.argv[process.argv.length - 1];
// const contract = JSON.parse(fs.readFileSync(jsonfile));
// console.log(JSON.stringify(contract.abi));
