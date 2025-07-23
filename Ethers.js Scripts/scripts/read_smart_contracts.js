require("dotenv").config()
const { ethers } = require("ethers")

// Setup connection
const URL = `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`
const provider = new ethers.JsonRpcProvider(URL)

// Define "Application Binary Interface"
const ERC20_ABI = [
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address owner) view returns (uint256)",
]

// Setup contract
const ERC20_ADDRESS = "0x514910771AF9Ca656af840dff83E8264EcF986CA"
const contract = new ethers.Contract(ERC20_ADDRESS, ERC20_ABI, provider)

async function main() {
  // Get contract state
  const name = await contract.name()
  const symbol = await contract.symbol()
  const decimals = await contract.decimals()
  const totalSupply = await contract.totalSupply()


  // Log contract state
  console.log(`\nReading from: ${ERC20_ADDRESS}\n`)
  console.log(`Contract Name: ${name}`)
  console.log(`Contract Symbol: ${symbol}`)
  console.log(`Contract Decimals: ${decimals}`)
  console.log(`Total Supply: ${ethers.formatUnits(totalSupply, decimals)} ${symbol}\n`)


  // Get ERC20 balance
  const USER_ADDRESS = "0xDB861E302EF7B7578A448e951AedE06302936c28"
  const balance = await contract.balanceOf("0xDB861E302EF7B7578A448e951AedE06302936c28")

  // Log ERC20 balance
  console.log(`Balance of ${USER_ADDRESS}: ${ethers.formatUnits(balance, decimals)} ${symbol}\n`)
}

main()