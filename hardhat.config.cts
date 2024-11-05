// from @nomicfoundation/hardhat-toolbox-viem to avoid module issue
import '@nomicfoundation/hardhat-ignition-viem'
import '@nomicfoundation/hardhat-verify'
import '@nomicfoundation/hardhat-viem'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import './tasks/hardhat-deploy-viem.cjs'

import dotenv from 'dotenv'
import 'hardhat-abi-exporter'
import 'hardhat-contract-sizer'
import 'hardhat-deploy'
import { HardhatUserConfig } from 'hardhat/config'


// hardhat actions
import './tasks/esm_fix.cjs'

// Load environment variables from .env file. Suppress warnings using silent
// if this file is missing. dotenv will never modify any environment variables
// that have already been set.
// https://github.com/motdotla/dotenv
dotenv.config({ debug: false })

let real_accounts = undefined
if (process.env.DEPLOYER_KEY) {
  real_accounts = [
    process.env.DEPLOYER_KEY,
    process.env.OWNER_KEY || process.env.DEPLOYER_KEY,
  ]
}

// circular dependency shared with actions
export const archivedDeploymentPath = './deployments/archive'

const config = {
  defaultNetwork: "sepolia",
  networks: {
    hardhat: {
      chainId: 1,
      forking: {
        enabled: true,
        url: "https://mainnet.infura.io/v3/8b75f801668e4304bbfad6e8b82aaf0c"
      },
      accounts: { privateKey: process.env.PRIVATE_KEY, balance: "1000000000000000000000" }
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/8b75f801668e4304bbfad6e8b82aaf0c",
      chainId: 11155111,
      accounts: [process.env.PRIVATE_KEY]
    },
    baseSepolia: {
      url: "https://sepolia.base.org",
      chainId: 84532,
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  mocha: {},
  solidity: {
    compilers: [
      {
        version: '0.8.25',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1200,
          },
        },
      },
      // for DummyOldResolver contract
      {
        version: '0.4.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  abiExporter: {
    path: './build/contracts',
    runOnCompile: true,
    clear: true,
    flat: true,
    except: [
      'Controllable$',
      'INameWrapper$',
      'SHA1$',
      'Ownable$',
      'NameResolver$',
      'TestBytesUtils$',
      'legacy/*',
    ],
    spacing: 2,
    pretty: true,
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    owner: {
      default: 0
    },
  },
  external: {
    contracts: [
      {
        artifacts: [archivedDeploymentPath],
      },
    ],
  },
} satisfies HardhatUserConfig

export default config
