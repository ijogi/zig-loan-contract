// SPDX-License-Identifier: GPL-3.0

// Avoid integer overflows as a language feature from 0.8
pragma solidity >=0.8.0 <0.9.0;

contract LoanContract {
    address public owner;
    // The ratio between the loan amount and the collateral to be put down e.g. 2:1
    uint public collateralRatio;
    // The percentage for reward payout to lenders based on the collateral provided by the borrower
    uint public rewardPercentage;

    struct Loan {
        address borrower;
        address lender;
        uint amount;
        uint expiresAt;
        uint collateral;
        uint rewardPercentage;
    }

    mapping(address => Loan) public loans;
    address[] public borrowers;

    modifier isOwner() {
        require(msg.sender == owner, "Not Owner Fuck Off");
        _;
    }
    
    constructor(uint _collateralRatio, uint _rewardPercentage) {
        collateralRatio = _collateralRatio;
        rewardPercentage = _rewardPercentage;
        owner = msg.sender;
    }

    function setCollateralRatio(uint _collateralRatio) public isOwner {
        collateralRatio = _collateralRatio;
    }

    function setRewardPercentage(uint _rewardPercentage) public isOwner {
        rewardPercentage = _rewardPercentage;
    }

    function createLoan(uint _amount, uint _expiresAt) payable public { // maybe include a require for collateral ratio <1 need float
        require(msg.value >= _amount * collateralRatio, "Not enough funds to create loan");
        Loan memory loan = Loan({
            borrower: msg.sender,
            lender: address(0),
            amount: _amount,
            expiresAt: _expiresAt,
            collateral: msg.value - _amount,
            rewardPercentage: rewardPercentage
        });

        loans[msg.sender] = loan;
        borrowers.push(msg.sender);
    }

    function financeLoan(address _borrower) payable public {
        Loan memory loan = loans[_borrower];
        require(msg.value >= loan.amount, "Not enough funds to fund the loan");
        require(loan.borrower != msg.sender, "We don't advise funding your own loan");
        loan.lender = msg.sender;
        loans[_borrower] = loan;

        payable(loan.borrower).transfer(loan.amount);
    }

    function repayLoan() payable public {
        Loan memory loan = loans[msg.sender];
        require(msg.value >= loan.amount, "The amount is not big enough to pay back the loan");
        require(loan.lender != address(0), "This loan has no lender");
        //require loan not expired, if statement then to liquidateloan 
        uint reward = ((loan.amount * loan.rewardPercentage) / 100);
        payable(loan.lender).transfer(loan.amount + reward);
        payable(loan.borrower).transfer(loan.amount * collateralRatio - reward);
        removeLoan(loan);
        
    }

    function liquidateLoan(address _borrower) payable public {
        Loan memory loan = loans[_borrower];
        require(msg.sender == loan.lender);
        require(loan.expiresAt < block.timestamp);
        uint reward = ((loan.amount * loan.rewardPercentage) / 100);
        payable(loan.lender).transfer(loan.amount + reward);
        payable(_borrower).transfer(loan.amount - reward);
        removeLoan(loan);
        
    }

    function removeLoan(Loan memory loan) private {
        Loan memory emptyLoan = Loan({
            borrower: address(0),
            lender: address(0),
            amount: 0,
            expiresAt: 0,
            collateral: 0,
            rewardPercentage: 0
        });
        loans[loan.borrower] = emptyLoan;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    fallback() external payable {}

    receive() external payable {}
}