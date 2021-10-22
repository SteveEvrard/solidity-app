var CardGame = artifacts.require("./CardGame.sol");
var CardAuction = artifacts.require("./CardAuction.sol");

module.exports = function(deployer) {
    deployer.then(async() => {
        await deployer.deploy(CardAuction);
        await deployer.deploy(CardGame, CardAuction.address);
    });
}