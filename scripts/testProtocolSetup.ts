import type { DeployFunction } from 'hardhat-deploy/types.js'
import { decodeAbiParameters, encodeAbiParameters, encodeFunctionData, encodePacked, hexToBigInt, keccak256, labelhash, namehash, parseAbi, zeroAddress, zeroHash } from 'viem'
import hre from 'hardhat'
import { encodeContentHash, generateRecordCallArray } from '@ensdomains/ensjs/utils'


import contractAddresses from './contractAddresses.json'
import { writeFileSync } from 'fs'



const func = async function () {
    const { deployments, network, viem, userConfig } = hre
  
    // console.log(registryChain.address)
    const userAddress = network.name == "hardhat" ? "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266": "0x1CA2b10c61D0d92f2096209385c6cB33E3691b5E"

    await deployProtocolWideContract("BasicToken", "BasicToken", [])
    await deployProtocolWideContract("DownToken", "DownToken", [contractAddresses[network.name]["BasicToken"]])
    await deployProtocolWideContract("UpToken", "UpToken", [contractAddresses[network.name]["BasicToken"]])
    await deployProtocolWideContract("SBT", "SBT", [contractAddresses[network.name]["DownToken"], contractAddresses[network.name]["UpToken"]])

    const BasicToken = await viem.getContractAt("BasicToken", contractAddresses[network.name]["BasicToken"])
    const DownToken = await viem.getContractAt("DownToken", contractAddresses[network.name]["DownToken"])
    const UpToken = await viem.getContractAt("UpToken", contractAddresses[network.name]["UpToken"])

        // Registrar needs to own 'registry' name on registry. This EntityRegistrar gives TLDs for registrars (country-level)
    const setRepTokens = await BasicToken.write.setReputationTokens([
      contractAddresses[network.name]["DownToken"],
      contractAddresses[network.name]["UpToken"]
    ])

    await viem.waitForTransactionSuccess(setRepTokens)


    const setUpSBT = await UpToken.write.setSBT([contractAddresses[network.name]["SBT"]])
    await viem.waitForTransactionSuccess(setUpSBT)

    const setDownSBT = await DownToken.write.setSBT([contractAddresses[network.name]["SBT"]])
    await viem.waitForTransactionSuccess(setDownSBT)


    const transferTx = await DownToken.write.transfer(["0x0219DB862b2b48969Df880BCd134e192Fd306bfA", 5000000000000000000n])
    await viem.waitForTransactionSuccess(transferTx)

    // checkSenders("0x0219DB862b2b48969Df880BCd134e192Fd306bfA")
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



    async function deployProtocolWideContract(key, name, args) {
      const depo = await viem.deployContract(name, args)
      console.log(key + " Address: ", depo.address)
      contractAddresses[network.name][key] = depo.address
      writeAddressesToFile(contractAddresses)
      return depo
    }


    async function deployUpgradeableContract(key, name, initArgs) {
      const logic = (await deployProtocolWideContract(key, name, []));
      const initAbis = {
        EntityFactory: ["function initialize(address,address,address,bytes) external"],
        EntityRegistrar: ["function initialize(address,bytes32,address,uint256,address) external"]
      }
      
      const initData = encodeFunctionData({
        abi: parseAbi(initAbis[name]),
        functionName: 'initialize',
        args: initArgs,
      });
      
      const proxyAdmin = "0x30CF84E121F2105e638746dCcCffebCE65B18F7C"; // Replace with your proxy admin address
      const proxy = (await deployProtocolWideContract(key, "TransparentUpgradeableProxy", [logic.address, proxyAdmin, initData]))


      contractAddresses[network.name][key] = proxy.address
      writeAddressesToFile(contractAddresses)

    }

    async function upgradeProxyContract(key, name) {

      const proxyAddress = contractAddresses[network.name][key]
      // Step 1: Deploy the new logic contract
      const newLogic = await deployProtocolWideContract(key, name, []);
  
      // Step 2: Upgrade the proxy contract with the new logic address
      const proxyAdminAbi = [
        "function upgradeTo(address) external"
    ];


    const proxy = await viem.getContractAt("TransparentUpgradeableProxy", proxyAddress)

    await proxy.write.upgradeTo([newLogic.address])

    console.log(`Proxy upgraded with new logic`);
  
  }


}

const checkSenders = async (target) => {
  const DownToken = await viem.getContractAt("DownToken", contractAddresses[network.name]["DownToken"])
  const UpToken = await viem.getContractAt("UpToken", contractAddresses[network.name]["UpToken"])

  const readDownRatings = await DownToken.read.getSenderRatingsListForTarget([target])
  const readUpRatings = await UpToken.read.getSenderRatingsListForTarget([target])

  console.log(readDownRatings, readUpRatings)
  // const downRatingDecode = decodeAbiParameters([{ type: 'address[]' }, {type: "uint256[]"}], readDownRatings)[0]
  // const upRatingDecode = decodeAbiParameters([{ type: 'address[]' }, {type: "uint256[]"}], readUpRatings)[0]

  // console.log(downRatingDecode)

  // const userBytesArray = txDataArray.map(data => decodeAbiParameters([
  //   { type: 'address' },
  //   { type: 'uint256' },
  //   { type: 'bytes' }
  // ], data))
  

}


function writeAddressesToFile(addresses) {
  const fileName = './scripts/contractAddresses.json';

  // Write the merged addresses back to the file
  writeFileSync(fileName, JSON.stringify(addresses, null, 2), 'utf-8');
  // console.log(`Addresses written to ${fileName}`);
}
checkSenders("0x0219DB862b2b48969Df880BCd134e192Fd306bfA")
// func()

export default func
