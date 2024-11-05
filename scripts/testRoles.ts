import type { DeployFunction } from 'hardhat-deploy/types.js'
import { encodeAbiParameters, encodePacked, keccak256, labelhash, namehash, zeroAddress, zeroHash } from 'viem'
import hre from 'hardhat'


const func: DeployFunction = async function () {
    const { deployments, network, viem } = hre
    const { run } = deployments
    // const { deployer, owner } = 
    // console.log(deployer.address, userAddress)
    // console.log('ADDR: ', process.env.DEPLOYER_KEY, process.env.OWNER_KEY)

    const roleDef = await viem.deployContract('RoleDefinitions', []) // 
    console.log(roleDef.address)

    
    // const roleDef = await viem.getContractAt('RoleDefinitions', "0x69f94e46cbc82ab02781ac4fafc3580d21f1a888")
    // console.log(await roleDef.read.generateDummyUserRoleData())
    console.log(await roleDef.read.ROLE_OWNER(), await roleDef.read.ROLE_MANAGER(), await roleDef.read.ROLE_INVESTOR(), await roleDef.read.ROLE_SPENDER(), await roleDef.read.ROLE_SIGNER())
    
    // 0x30CF84E121F2105e638746dCcCffebCE65B18F7C

    const user1 = encodeUser("0x1ca2b10c61d0d92f2096209385c6cb33e3691b5e", ["owner", "manager"])
    const user2 = encodeUser("0x30cf84e121f2105e638746dcccffebce65b18f7c", ["owner", "manager", "investor", "signer", "spender"])
    

    const multisig = await viem.deployContract('Multisig', [1, roleDef.address, [user1, user2]])
    console.log(multisig.address)

    // const multisig = await viem.getContractAt('Multisig', "0xe0a1556ef66873d965a2f4cad06f051646be6707")

    console.log("owner", await multisig.read.hasRole(["0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0", "0x1CA2b10c61D0d92f2096209385c6cB33E3691b5E"]))
    console.log("manager", await multisig.read.hasRole(["0x2447c43a6160806768d4c947ce727fb12b7f2700badae716947943ea245c25d6", "0x1CA2b10c61D0d92f2096209385c6cB33E3691b5E"]))
    console.log("spender", await multisig.read.hasRole(["0x49b2c05ea4541c2d950c8dd66a6ebbc5886c7039b397b1d8e19a29e77dd9bdcc", "0x1CA2b10c61D0d92f2096209385c6cB33E3691b5E"]))
    console.log("investor", await multisig.read.hasRole(["0x4defcbe185079e8fa77f7b9fc7063c614fab765cfcb6e3ee77b6d44cbd033288", "0x1CA2b10c61D0d92f2096209385c6cB33E3691b5E"]))
    console.log("signer", await multisig.read.hasRole(["0x6c8d7f768a6bb4aafe85e8a2f5a9680355239c7e14646ed62b044e39de154512", "0x1CA2b10c61D0d92f2096209385c6cB33E3691b5E"]))
    
    console.log("owner", await multisig.read.hasRole(["0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0", "0x30CF84E121F2105e638746dCcCffebCE65B18F7C"]))
    console.log("manager", await multisig.read.hasRole(["0x2447c43a6160806768d4c947ce727fb12b7f2700badae716947943ea245c25d6", "0x30CF84E121F2105e638746dCcCffebCE65B18F7C"]))
    console.log("spender", await multisig.read.hasRole(["0x49b2c05ea4541c2d950c8dd66a6ebbc5886c7039b397b1d8e19a29e77dd9bdcc", "0x30CF84E121F2105e638746dCcCffebCE65B18F7C"]))
    console.log("investor", await multisig.read.hasRole(["0x4defcbe185079e8fa77f7b9fc7063c614fab765cfcb6e3ee77b6d44cbd033288", "0x30CF84E121F2105e638746dCcCffebCE65B18F7C"]))
    console.log("signer", await multisig.read.hasRole(["0x6c8d7f768a6bb4aafe85e8a2f5a9680355239c7e14646ed62b044e39de154512", "0x30CF84E121F2105e638746dCcCffebCE65B18F7C"]))
}

const encodeUser = (userAddress, roles) => {
    const encodedRoles = (encodePacked(roles.map(x => "bytes32"), roles.map(role => keccak256(role))))
    const encodedUserData = (encodeAbiParameters([{type:"address"}, {type: "bytes"}], [userAddress, encodedRoles]))
    return encodedUserData

}
func()

export default func
