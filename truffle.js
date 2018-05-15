module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  /** 
   * Ropsten 
   * ------------
   * testnet: PoW (proof-of-work)
   * Cons: not immune to spam attacks.
   * Network id: 3
   * Block time: sub-30 seconds
   * Commands: geth --testnet or geth --network 3
   * Explorer: https://repsten.etherscan.io
   * Github: https://github.com/ethereum/ropsten
   * 
   * Rinkeby
   * ------------
   * testnet: PoA (proof-of-authority)
   * Cons: ether can't be mined. it has to be requested from a faucet: https://faucet.rinkeby.io
   * Network id: 4
   * Block time: 15 seconds
   * Commands: geth --rinkeby or geth --networkid 4
   * Explorer: https://rinkeby.etherscan.io
   * Github: https://github.com/ethereum/EIPs/issues/225
   * Website: https://wwww.rinkeby.io
  */
  // 
  // 
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "5777"
        },
        main: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "1"
        },
        ropsten: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "3"
        }
    }
};
