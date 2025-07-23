// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";




enum Status {active, repaid, defaulted}

struct Loan {
    address borrower;
    address nftContract;
    uint256 tokenId;
    uint256 collateralAmount;
    // uint256 loanedToken; //erc20 or eth?
    uint256 loanedAmount;
    uint256 startTime;
    uint256 dueTime;
    Status status;
}


contract LoanVault is Ownable {

    IERC20 public ERC20; //the token we loan

    uint256 public vaultEthBalance;
    uint256 public vaultERC20Balance;

    mapping (address => mapping (uint256 => uint256)) public whitelistedNFTs;  //nft contract address => tokenId => tokenValue in eth
    mapping (uint256 => Loan) loans; //loanID => Loan data
    uint256 nextLoanId = 0;

    uint256 interestRate = 5;

    error LowAccountTokenBalance();
    error LowVaultETHBalance();
    error LowVaultTokenBalance();
    error ZeroAmountDeposit();
    error IneligibleNFT();
    error LoanDurationTooLong();
    error AmountOutOfAllowedRange();
    error InauthorizedReturner();
    error LoanAlreadyExpired();
    error LoanNotActive();
    error LoanNotYetDefaulted();


    event DepositMadetoVault(address indexed depositer);
    event AmountWithdrawnFromVault(address indexed withdrawer);
    event LoanAwarded(address indexed borrower, uint256 principalAmount, uint256 loanId, uint256 collateralTokenId, address collateralNftContract);
    event LoanReturned(address indexed borrower, uint256 returnedAmount, uint256 loanId);
    event CollateralClaimed(address indexed claimer, uint256 loanAmount, uint256 loanId, uint256 loanedTokenId, address loanedNftContract );

    constructor (address initialOwner, address ERC20Token) Ownable(initialOwner) {
        ERC20 = IERC20(ERC20Token);// the token we loan
    }

    modifier sufficientAccountBalanceERC20( uint256 amount) {
        if (ERC20.balanceOf(msg.sender) < amount)
        {
            revert LowAccountTokenBalance();
        }
        _;
    }


    modifier sufficientVaultBalanceERC20( uint256 amount) {
        if (vaultERC20Balance < amount)
        {
            revert LowVaultTokenBalance();
        }
        _;
    }

    // modifier sufficientAccountBalanceETH(address from, uint256 amount) {
    //     if (ERC20.balanceOf(msg.sender) < amount)
    //     {
    //         revert LowAccountETHBalance();
    //     }
    //     _;
    // }


    // modifier sufficientVaultBalanceETH( uint256 amount) {
    //     if (vaultEthBalance < amount)
    //     {
    //         revert LowVaultETHBalance();
    //     }
    //     _;
    // }

    function editWhitelistedToken(
        address nftContract,
        uint256 tokenId,
        uint256 value //in token (usdt)
    ) public onlyOwner {
        whitelistedNFTs[nftContract][tokenId] = value;
    }

    function removeWhitelistedToken (
        address nftContract,
        uint256 tokenId
    ) public onlyOwner {
        delete whitelistedNFTs[nftContract][tokenId];
    }

    function depositERC20   ( uint256 amount) 
        public 
        onlyOwner 
        sufficientAccountBalanceERC20(amount)
        returns (bool success) 
    {
        if (amount < 0) {
            revert ZeroAmountDeposit();
        }
        success = ERC20.transferFrom(msg.sender, address(this), amount);
        vaultERC20Balance += amount;
        //emit an event that an amount was dposited?
        emit DepositMadetoVault(msg.sender);

        return success;
    }

    // function depositETH()
    //     public 
    //     payable 
    //     onlyOwner
    // {
    //     require(msg.value > 0, "No ETH sent"); //change to custom error
    //     vaultEthBalance += msg.value;
    //     //emit an event that amount was deposited

    // }

    function withdrawERC20 ( uint256 amount) 
        public 
        onlyOwner
        sufficientVaultBalanceERC20(amount)
        returns (bool success)
    {
        
        vaultERC20Balance -= amount;
        success = ERC20.transferFrom(address(this), owner(), amount);
        //emit event that amount was withdrawn
        emit AmountWithdrawnFromVault(msg.sender);
        return success;
    }

    // function withdrawETH(uint256 amount)
    //     public 
    //     onlyOwner
    //     sufficientVaultBalanceETH(amount)
    //     returns (bool success)
    // {
    //     vaultEthBalance -= amount;
    //     (success, ) = payable(owner()).call{value: amount}("");
    //     require(success, "ETH withdraw failed");//create specific error
    //     //emit event
    //     return success;
    // }
    
    function calculateInterest(uint256 principal, uint256 secsElapsed)
    public
    view
    returns (uint256 interest)
    {
        // interest = principal × APR(%) × time / (100 × year)
        interest = principal * interestRate * secsElapsed / 31536000; //div by an year
    }


    function requestLoan(
        address nftContract, 
        uint256 tokenId, 
        uint256 principal, 
        uint256 duration //in months
    ) public //currently just doing on ETH
        returns (uint256)
    {

        uint256 value = whitelistedNFTs[nftContract][tokenId];
        if (value <= 0) {
            revert IneligibleNFT();
        }

        if (duration > 120) {
            revert LoanDurationTooLong();
        }


        uint256 minLoan = value / 20;
        uint256 maxLoan = value /2;
        if (minLoan > principal || maxLoan < principal) {
            revert AmountOutOfAllowedRange();
        }


        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        uint256 loanId = nextLoanId;
        nextLoanId++;


        loans[loanId] = Loan({
            borrower: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            collateralAmount: value,
            // loanedToken: requestedToken,
            loanedAmount: principal,
            startTime: block.timestamp,
            dueTime: block.timestamp + duration,
            status: Status.active
        });
        vaultERC20Balance -= principal;
        ERC20.transfer(msg.sender, principal);

        emit LoanAwarded(msg.sender, principal, loanId, tokenId, nftContract);

        return loanId;

        

    }

    function repayLoan(uint256 loanId) public
    {
        Loan storage loan = loans[loanId];
        if (loan.borrower != msg.sender) {
            revert InauthorizedReturner();
        }

        if (block.timestamp > loan.dueTime) {
            revert LoanAlreadyExpired();
        }

        if (loan.status != Status.active) {
            revert LoanNotActive();
        }

        uint256 secs = block.timestamp - loan.startTime;
        uint256 interest = calculateInterest(loan.loanedAmount, secs);

        uint256 amountDue = loan.loanedAmount + interest;
        ERC20.transferFrom(msg.sender, owner(), amountDue);

        loan.status = Status.repaid;

        IERC721(loan.nftContract).transferFrom(address(this), msg.sender, loan.tokenId);

        //emit event that loan repaid?
        emit LoanReturned(msg.sender, amountDue, loanId);
    }

    function claimCollateral(uint256 loanId) external onlyOwner
    {
        Loan storage loan = loans[loanId];
        if (loan.status != Status.active) {
            revert LoanNotActive();
        }

        if (block.timestamp <= loan.dueTime) {
            revert LoanNotYetDefaulted();
        }
        loan.status = Status.defaulted;
        IERC721(loan.nftContract).transferFrom(address(this), owner(), loan.tokenId);

        //emit event that loan defaulted
        emit CollateralClaimed(msg.sender, loan.loanedAmount, loanId, loan.tokenId, loan.nftContract );
    }
        


    


}
/*Required methods:
NFT whitelist (onlyOwner)
claiming default (onlyOwner


Required Features:

1. Collateralization (Borrower):

Borrower locks an NFT (ERC-721 or ERC-1155) into the contract.

Specifies requested loan amount, duration, and accepted token type (ETH or ERC-20).

2. Loan Funding (Lender):

Lender can accept the loan terms and fund the loan with ETH or a specified ERC-20 token.

Once funded, loan terms become locked, and the borrower receives the funds.

3. Loan Repayment:

Borrower repays the loan (principal + interest) before the deadline.

On successful repayment, NFT collateral is returned to the borrower.

4. Collateral Claim (Default Handling):

If the loan isn’t repaid on time, the lender can claim the NFT permanently.

5. Token Support:

Accept ETH and user-defined ERC-20 tokens for loans.

6. Loan Management:

Track loan status: active, repaid, defaulted.

Track key data: borrower, lender, collateral NFT, repayment amount, due



First I create contract that created nfts, (will try with both 721 and 1155) i then whitelist these nfts for loan in the vault contract. 

I then create a vault contract. This contract will have an owner who will be the lender, it will also have whitelisted nfts that can be used to get the loan. 
When the borrower comes and asks for a loan we check if the nft given is whitelisted, if it is not we transfer it back and give the error to the borrower. If it is whitelisted
we check the if the loan amount falls within the minmum and maximum range (if not we return error)if it does we keep the nft and transfer the loan in the specified erc-20 or eth, we also take the duration
terms of months. If the borrower repays the loan in the speifed timeframe (calls the loanRetrun method) they will pay the amount and the vault will trasnfer back the the NFT. 
However if the loan is not repaid in the specified timeframe, the loan status will become defaulted and the lender (loan owner) can call the claim method to get hte nft withdrawn and transferred to their account.  */ 
