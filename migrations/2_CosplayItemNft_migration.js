const CosplayItemNft = artifacts.require("CosplayItemNft");

module.exports = function (deployer) {
  deployer.deploy(CosplayItemNft);
};
