// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/BasicCopper.sol";
import "../src/ShittyCopper.sol";
import "../src/FineCopper.sol";
import "../src/SBT.sol";

contract DeployContracts is Script {
    function run() external {
        // Get the deployer's private key from the environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);

        // Deploy BasicCopper contract
        BasicCopper basicCopper = new BasicCopper();

        // Deploy ShittyCopper contract
        ShittyCopper shittyCopper = new ShittyCopper(address(basicCopper));

        // Deploy FineCopper contract
        FineCopper fineCopper = new FineCopper(address(basicCopper));

        // Deploy SBT contract
        SBT sbt = new SBT(address(shittyCopper), address(fineCopper));

        // Set the Reputation tokens in BasicCopper
        basicCopper.setReputationTokens(address(shittyCopper), address(fineCopper));

        // Set the SBT contract for the Reputation tokens
        shittyCopper.setSBT(address(sbt));
        fineCopper.setSBT(address(sbt));

        // Stop broadcasting transactions
        vm.stopBroadcast();

        console.log("BasicCopper deployed at:", address(basicCopper));
        console.log("ShittyCopper deployed at:", address(shittyCopper));
        console.log("FineCopper deployed at:", address(fineCopper));
        console.log("SBT deployed at:", address(sbt));
    }
}
