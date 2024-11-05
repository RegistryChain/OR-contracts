import type { DeployFunction } from 'hardhat-deploy/types.js'
import { labelhash, namehash, zeroAddress, zeroHash } from 'viem'
import hre from 'hardhat'
import { getInterfaceId } from '../test/fixtures/createInterfaceId'
import { toLabelId, toTokenId } from '../test/fixtures/utils'
import { dnsEncodeName } from '../test/fixtures/dnsEncodeName'



const func: DeployFunction = async function () {
    const { deployments, network, viem } = hre
    const { run } = deployments
    // const { deployer, owner } = 
    // console.log(deployer.address, userAddress)
    // console.log('ADDR: ', process.env.DEPLOYER_KEY, process.env.OWNER_KEY)

    const registry = await viem.getContractAt("ENSRegistry", "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")

    console.log(registry.address)

    const userAddress = "0x1CA2b10c61D0d92f2096209385c6cB33E3691b5E"

    const registrarController = await viem.getContractAt("ETHRegistrarController", "0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72")
    const baseRegistrar = await viem.getContractAt("BaseRegistrarImplementation", "0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85")
    const ownedResolver = await viem.getContractAt("OwnedResolver", "0x8FADE66B79cC9f707aB26799354482EB93a5B7dD")

    // const publicSubdomainRegistrar = await viem.deployContract('FIFSRegistrar', ["0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e", namehash('publicunwrap.eth')])
    // console.log(publicSubdomainRegistrar.address)

    // const tx = await registrar.write.register([toLabelId('newname'), userAddress, 86400n])

    // await ownedResolver.write.setName([namehash('manzano.eth'), "CUSTOM NAME"])
    // const setTextTx = await ownedResolver.write.setText([namehash('manzano.eth'), "MAIN1", "blah"])

    // console.log(labelhash("dnsname"), namehash("dnsname.ens.eth"), namehash("dnsname.ens.eth"))


    const nameWrapper = await viem.getContractAt('NameWrapper', "0x0635513f179D50A207757E05759CbD106d7dFcE8")


    // await addWrappedSubdomain(nameWrapper, 'pubic.eth', "a", userAddress, ownedResolver.address)




    await readOwner(registry, "publicregistry1.eth", "test1")


    // UNWRAP [registrar].eth AND ISSUE SUBDOMAINS
    let publicSubdomainRegistrar = await viem.getContractAt("FIFSRegistrar", "0x5e366e2edb2126ff508dacaed8515dd8cf76f833")
    // let publicSubdomainRegistrar = await convertNameToSubdomainRegistrar("publicregistry1", nameWrapper, viem)
    await addSubdomain(publicSubdomainRegistrar, userAddress, "test1", viem)




    await readOwner(registry, "publicregistry1.eth", "test1")


}

const convertNameToSubdomainRegistrar = async (parentLabel, nameWrapperContract, viem) => {
    const publicSubdomainRegistrar = await viem.deployContract('FIFSRegistrar', ["0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e", namehash(parentLabel + '.eth')])
    console.log(publicSubdomainRegistrar.address)

    const unwrap = await nameWrapperContract.write.unwrapETH2LD([
        labelhash(parentLabel),
        publicSubdomainRegistrar.address,
        publicSubdomainRegistrar.address
    ], { gas: 1000000n })
    await viem.waitForTransactionSuccess(unwrap)
    console.log('arrived')

    return publicSubdomainRegistrar
}

const addSubdomain = async (publicSubdomainRegistrar, userAddress, label, viem) => {
    console.log(labelhash(label), label)
    const tx = await publicSubdomainRegistrar.write.register([label, userAddress, "0x8fade66b79cc9f707ab26799354482eb93a5b7dd"], { gas: 1000000n })
    await viem.waitForTransactionSuccess(tx)

}

const addWrappedSubdomain = async (nameWrapperContract, parent, newSubdomain, userAddress, resolverAddress) => {
    await nameWrapperContract.write.setSubnodeRecord(
        [namehash(parent),
            newSubdomain,
            userAddress,
            resolverAddress,
            0n,
            0,
            2021232060n]
    )
}

const readOwner = async (registry, parent, subname) => {
    console.log("parent owner: ", await registry.read.owner([namehash(parent)]))
    if (subname) {
        console.log("subname owner: ", await registry.read.owner([namehash(subname + '.' + parent)]))
    }

}

func()

export default func
