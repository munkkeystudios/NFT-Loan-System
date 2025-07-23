require("dotenv").config()
const { ethers } = require("ethers")

// Import private key helper
const { promptForKey } = require("../helpers/prompt.js")

// Setup connection
const URL = process.env.TENDERLY_RPC_URL
const provider = new ethers.JsonRpcProvider(URL)

// Define "Application Binary Interface"
const ERC20_ABI = [
  "function decimals() view returns (uint8)",
  "function balanceOf(address) view returns (uint256)",
  "function transfer(address to, uint amount) returns (bool)",
];

// Setup contract
const ERC20_ADDRESS = "0x514910771AF9Ca656af840dff83E8264EcF986CA" // Chainlink Contract
const contract = new ethers.Contract(ERC20_ADDRESS, ERC20_ABI, provider)

// Define reciever
const RECIEVER = "0x1251414530DF98448D4da412121D77455399eCcF" // Your account address 2

async function main() {
  const privateKey = await promptForKey()

  // Setup wallet
  const wallet = new ethers.Wallet(privateKey, provider)

  // Get ERC20 balances
  const senderBalanceBefore = await contract.balanceOf(wallet.address)
  const recieverBalanceBefore = await contract.balanceOf(RECIEVER)

  // Log ERC20 balances
  console.log(`\nReading from ${ERC20_ADDRESS} :`)
  console.log(`Sender balance before: ${ethers.formatUnits(senderBalanceBefore, 18)} LINK`)
  console.log(`Reciever balance before: ${ethers.formatUnits(recieverBalanceBefore)} LINK\n`)

  // Setup amount to transfer
  const decimals = await contract.decimals()
  const AMOUNT = ethers.parseUnits("1", decimals) // 1 LINK token

  // Create transaction
  const transaction = await contract.connect(wallet).transfer(RECIEVER, AMOUNT)

  // Wait transaction
  await transaction.wait()

  // Log transaction
  console.log(transaction)

  // Get ERC20 balances
  const senderBalanceAfter = await contract.balanceOf(wallet.address)
  const recieverBalanceAfter = await contract.balanceOf(RECIEVER)

  console.log(`\nBalance of sender: ${ethers.formatUnits(senderBalanceAfter, decimals)} LINK`)
  console.log(`Balance of reciever: ${ethers.formatUnits(recieverBalanceAfter, decimals)} LINK\n`)
}

main()