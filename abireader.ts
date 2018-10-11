const fs = require('fs');
const jsonfile = process.argv[process.argv.length - 1];
const contract = JSON.parse(fs.readFileSync(jsonfile));
console.log(JSON.stringify(contract.abi));
