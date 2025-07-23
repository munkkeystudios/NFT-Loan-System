require("dotenv").config()
const { ethers } = require("ethers")

// Setup connection
const URL = `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`
const provider = new ethers.JsonRpcProvider(URL)

// Define "Application Binary Interface"
const ERC20_ABI = [
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",

  "event Transfer(address indexed from, address indexed to, uint256 value)",
];

// Setup contract
const ERC20_ADDRESS = '0x514910771AF9Ca656af840dff83E8264EcF986CA' // LINK Contract
const contract = new ethers.Contract(ERC20_ADDRESS, ERC20_ABI, provider)

const main = async () => {
  // Get block number
  const block = await provider.getBlockNumber()

  // Query events
  const transferEvents = await contract.queryFilter("Transfer", block - 1, block)
  console.log(transferEvents[0])
  console.log(transferEvents.length)


}

main()