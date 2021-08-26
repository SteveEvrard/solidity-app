var CardOwnership = artifacts.require("./CardOwnership.sol");

module.exports = function(deployer) {
    deployer.deploy(CardOwnership);
}