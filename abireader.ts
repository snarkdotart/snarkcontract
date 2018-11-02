const fs = require('fs');
const path_contractservice = '../snarkfrontend/src/app/services/contracts.service.ts';
const dictionary = [
	['private SnarkBaseABI =', './build/contracts/SnarkBase.json'], 
	['private SnarkOfferBidABI =', './build/contracts/SnarkOfferBid.json'],
	['private SnarkLoanABI =', './build/contracts/SnarkLoan.json'],
	['private SnarkERC721ABI =', './build/contracts/SnarkERC721.json']
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
