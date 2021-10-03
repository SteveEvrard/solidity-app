var CardAuction = artifacts.require("./CardAuction.sol");

module.exports = function(deployer) {
    deployer.deploy(CardAuction);
}