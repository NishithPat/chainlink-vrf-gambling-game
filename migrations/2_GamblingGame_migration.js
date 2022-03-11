const GamblingGame = artifacts.require("GamblingGame");
const LinkTokenInterface = artifacts.require("LinkTokenInterface");

module.exports = async function (deployer, network, accounts) {
    const _N = 3;
    const _stakeAmount = web3.utils.toWei('0.001', 'ether');
    await deployer.deploy(GamblingGame, _N, _stakeAmount, { from: accounts[0] });
    const contractInstance = await GamblingGame.deployed();
    console.log("contract deployed at", contractInstance.address);

    const LINK = "0xa36085F69e2889c224210F603D836748e7dC0088";
    const tokenContract = await LinkTokenInterface.at(LINK);
    const tokenAmountToSend = web3.utils.toWei('0.5');
    await tokenContract.transfer(contractInstance.address, tokenAmountToSend, { from: accounts[0] });

    const LINK_Balance = await tokenContract.balanceOf(contractInstance.address);
    console.log("LINK balance of contract =", LINK_Balance.toString());
};