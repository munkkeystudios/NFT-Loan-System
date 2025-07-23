// Require packages
require("dotenv").config()
const {ethers} = require("ethers")


// Setup connection
const URL = `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`
const provider = new ethers.JsonRpcProvider(URL)

const ADDRESS = "0x3B932e1BBE73076995faE219f0B05F6546733EDF"

async function main() {
  // Get balance
  balance = await provider.getBalance(ADDRESS)
  // Log balance
  console.log(`\n ETH Balance of ${ADDRESS} -> ${ethers.formatUnits(balance, 18)} ETH\n`)

}

main()