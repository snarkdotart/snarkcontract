var HDWalletProvider = require("truffle-hdwallet-provider");
var SECRET_KEY='343434';
var PROJECT_ID='343434';

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
};
