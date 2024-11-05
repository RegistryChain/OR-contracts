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

  const registry = await viem.deployContract('ENSRegistry', [], {
    artifact: await deployments.getArtifact('ENSRegistry'),
  })

  sepoliaFork.ensRegistry.address = registry.address

  console.log(registry.address)

  const userAddress = await registry.read.owner([zeroHash])
  console.log(userAddress)
  const hash = await registry.write.setOwner([zeroHash, userAddress], {
    account: userAddress,
  })

  console.log('deploy root')
  const root = await viem.deployContract('Root', [registry.address])

  console.log('ROOT: ', root.address)


  // await registry.write.setOwner([zeroHash, root.address])

  const rootOwner = await root.read.owner()

  console.log('ROOT OWNER: ', rootOwner)

  const ownerIsRootController = await root.read.controllers([userAddress])
  if (!ownerIsRootController) {
    const setControllerHash = await root.write.setController(
      [userAddress, true],
      { account: userAddress },
    )
    console.log(
      `Setting final owner as controller on root contract (tx: ${setControllerHash})...`,
    )
    await viem.waitForTransactionSuccess(setControllerHash)
  }


  const registrar = await viem.deployContract('BaseRegistrarImplementation', [
    registry.address,
    namehash('registry'),
  ])

  sepoliaFork.ensBaseRegistrarImplementation.address = registrar.address

  console.log('Running base registrar setup')

  const transferOwnershipHash = await registrar.write.transferOwnership(
    [userAddress],
    { account: userAddress },
  )
  console.log(
    `Transferring ownership of registrar to owner (tx: ${transferOwnershipHash})...`,
  )
  await viem.waitForTransactionSuccess(transferOwnershipHash)

  console.log(await registry.read.owner(["0x0000000000000000000000000000000000000000000000000000000000000000"]))


//SHOULD BE ABLE TO SET TLD HERE
//   registry.setOwner(
//     bytes32 node,
//     address owner
// )

// WHERE NODE 

  const registrySuffixTransfer = await registry.write.setSubnodeOwner([
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    labelhash('registry'),
    registrar.address
  ])

  await viem.waitForTransactionSuccess(registrySuffixTransfer)


  const reverseRegistrar = await viem.deployContract('ReverseRegistrar', [
    registry.address,
  ])

  sepoliaFork.ensReverseRegistrar.address = reverseRegistrar.address

  console.log('REACHED?')

  const setReverseOwnerHash = await registry.write.setSubnodeOwner([
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    labelhash('reverse'),
    userAddress
  ])

  console.log(
    `Setting owner of .reverse to owner on root (tx: ${setReverseOwnerHash})...`,
  )
  await viem.waitForTransactionSuccess(setReverseOwnerHash)

  const setAddrOwnerHash = await registry.write.setSubnodeOwner(
    [namehash('reverse'), labelhash('addr'), reverseRegistrar.address],
    { account: userAddress },
  )
  console.log(
    `Setting owner of .addr.reverse to ReverseRegistrar on registry (tx: ${setAddrOwnerHash})...`,
  )
  await viem.waitForTransactionSuccess(setAddrOwnerHash)

  let metadataHost =
    process.env.METADATA_HOST || 'ens-metadata-service.appspot.com'

  if (network.name === 'localhost') {
    metadataHost = 'http://localhost:8080'
  }

  const metadataUrl = `${metadataHost}/name/0x{id}`

  const metadata = await viem.deployContract('StaticMetadataService', [metadataUrl])



  const nameWrapper = await viem.deployContract('NameWrapper', [
    registry.address,
    registrar.address,
    metadata.address,
  ])

  sepoliaFork.ensNameWrapper.address = nameWrapper.address

  await nameWrapper.write.setController([userAddress, true])

  // Only attempt to make controller etc changes directly on testnets

  await registrar.write.addController([
    userAddress,
  ])

  await registrar.write.addController([
    nameWrapper.address,
  ])

  const interfaceId = await getInterfaceId('INameWrapper')


  const publicResolver = await viem.deployContract('PublicResolver', [registry.address, nameWrapper.address, userAddress, reverseRegistrar.address])
  sepoliaFork.ensPublicResolver.address = publicResolver.address
  const setResolverHash = await registrar.write.setResolver(
    [publicResolver.address],
    { account: userAddress },
  )
  await viem.waitForTransactionSuccess(setResolverHash)

  const resolver = await registry.read.resolver([namehash('registry')])
  console.log(`set resolver for .registry to ${resolver}`)

  const setInterfaceHash = await publicResolver.write.setInterface([
    namehash('registry'),
    interfaceId,
    nameWrapper.address,
  ])
  console.log(
    `Setting NameWrapper interface ID ${interfaceId} on .eth resolver (tx: ${setInterfaceHash})...`,
  )
  await viem.waitForTransactionSuccess(setInterfaceHash)


  const universalResolver = await viem.deployContract('UniversalResolver', [registry.address, ["https://ccip-v2.ens.xyz"]])
  sepoliaFork.ensUniversalResolver.address = universalResolver.address

  const tx = await registrar.write.register([toLabelId('newname'), userAddress, 86400n])

  // await publicResolver.write.setName([namehash('newname.registry'), "CUSTOM NAME"])
  // await publicResolver.write.setText([namehash('newname.registry'), "MAIN", "MICHAEL MICHAEL MICHAEL MICHAEL MICHAEL MICHAEL MICHAEL MICHAEL MICHAEL MICHAEL "])


  // console.log(await registry.read.owner([namehash('newname.registry')]),
  //   await publicResolver.read.name([namehash('newname.registry')]),
  //   await publicResolver.read.text([namehash('newname.registry'), "MAIN"]),
  //   await registrar.read.ownerOf([toLabelId('newname')]))

  // const expiry = await registrar.read.nameExpires([toLabelId('newname')]);

  // await nameWrapper.write.wrap([
  //   dnsEncodeName('newname.registry'),
  //   userAddress,
  //   publicResolver.address
  // ])

  console.log(namehash("registry"))

  console.log(await registry.read.isApprovedForAll([userAddress, userAddress]))
  await registry.write.setApprovalForAll([userAddress, true])
  console.log(await registry.read.isApprovedForAll([userAddress, userAddress]))

  await nameWrapper.write.registerAndWrapETH2LD(["public",
    userAddress,
    86400n,
    publicResolver.address,
    0])

  console.log(await registry.read.owner([namehash('registry')]), nameWrapper.address)
  // await nameWrapper.write.wrapETH2LD(
  //   ["newname", // "myname.eth" but only the label
  //     userAddress, // The address you want to own the wrapped name
  //     0, // The owner-controlled fuse bits OR'd together, that you want to burn
  //     publicResolver.address] // The address of the resolver you want to use]
  // )
  console.log(await registry.read.owner([namehash('chaser.public.registry')]))

  // const tx2 = await registrar.write.register([toLabelId('chaser.public'), userAddress, 86400n])
  // console.log('Check')
  // await nameWrapper.write.setSubnodeOwner([namehash('public.registry'), "chaser", userAddress, 0, expiry])



  // console.log(await nameWrapper.read.owner([namehash('chaser.public.registry')]))

  console.log(sepoliaFork)

}
export const sepoliaFork = {

  "multicall3": {
    "address": "0xca11bde05977b3631167028862be2a173976ca11",
    "blockCreated": 751532
  },
  "ensRegistry": {
    "address": ""
  },
  "ensBaseRegistrarImplementation": {
    "address": ""
  },
  "ensNameWrapper": {
    "address": ""
  },
  "ensReverseRegistrar": {
    "address": ""
  },
  "ensPublicResolver": {
    "address": ""
  },
  "ensUniversalResolver": {
    "address": ""
  },
  "ensBulkRenewal": {
    "address": ""
  },
  "ensDnsRegistrar": {
    "address": ""
  },
  "ensDnssecImpl": {
    "address": ""
  },
  "ensEthRegistrarController": {
    "address": ""
  }
}

func()

export default func
