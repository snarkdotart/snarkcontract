require('dotenv').config();
var HDWalletProvider = require("truffle-hdwallet-provider");

var DEFAULT_VALUE = '343434';

var SECRET_KEY = (process.env.SECRET_KEY) ? process.env.SECRET_KEY : DEFAULT_VALUE;
var PROJECT_ID = (process.env.PROJECT_ID) ? process.env.PROJECT_ID : DEFAULT_VALUE;
var ETHERSCAN_KEY = (process.env.ETHERSCAN_KEY) ? process.env.ETHERSCAN_KEY : DEFAULT_VALUE;

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: 5777,
            gasPrice: 1
        },
        main: {
            provider: new HDWalletProvider(SECRET_KEY, "https://mainnet.infura.io/v3/" + PROJECT_ID),
            gas: 7900000,
            gasPrice: 7000000000, // 7 Gwei
            network_id: 1,
            confirmations: 2,
            skipDryRun: true,
        },
        ropsten: {
            provider: new HDWalletProvider(SECRET_KEY, "https://ropsten.infura.io/v3/" + PROJECT_ID),
            gas: 7900000,
            gasPrice: 7000000000, // 7 Gwei
            network_id: 3,
            confirmations: 2,
            skipDryRun: true,
        },
        rinkeby: {
            provider: new HDWalletProvider(SECRET_KEY, "https://rinkeby.infura.io/v3/" + PROJECT_ID),
            gas: 6900000,
            gasPrice: 7000000000, // 7 Gwei
            network_id: 4,
            confirmations: 2,
            skipDryRun: true,
        }
    },
    compilers: {
        solc: {
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                }
            }
        },
    },
    plugins: [
        'truffle-plugin-verify'
    ],
    api_keys: {
        etherscan: ETHERSCAN_KEY
    },
};
