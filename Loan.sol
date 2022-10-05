// SPDX-License-Identifier: GPL-3.0

// Avoid integer overflows as a language feature from 0.8
pragma solidity >=0.8.0 <0.9.0;

contract LoanContract {
    address public owner;
    // The ratio between the loan amount and the collateral to be put down e.g. 2:1
    uint8 public collateralRatio;
    // The percentage for reward payout to lenders based on the collateral provided by the loaner
    uint8 public rewardPercentage;

    struct Loan {
        address loaner;
        address lender;
        uint amount;
        uint expiresAt;
    }

    mapping(address => Loan) public loans;
    address[] public loaners;

    constructor(uint8 _collateralRatio, uint8 _rewardPercentage) {
        collateralRatio = _collateralRatio;
        rewardPercentage = _rewardPercentage;
    }

    function createLoan(uint _amount, uint _expiresAt) payable public {
        require(msg.value >= _amount * collateralRatio, "Not enough funds to create loan");
        Loan memory loan = Loan({
            loaner: msg.sender,
            lender: address(0),
            amount: _amount,
            expiresAt: _expiresAt
        });

        loans[msg.sender] = loan;
        loaners.push(msg.sender);
    }

    function financeLoan(address _loaner) payable public {
        Loan memory loan = loans[_loaner];
        require(msg.value >= loan.amount, "Not enough funds to fund the loan");
        require(loan.loaner != msg.sender, "We don't advise funding your own loan");
        loan.lender = msg.sender;
        loans[_loaner] = loan;

        payable(loan.loaner).transfer(loan.amount);
    }

    function repayLoan() payable public {
        Loan memory loan = loans[msg.sender];
        require(msg.value >= loan.amount, "The amount is not big enough to pay back the loan");
        require(loan.lender != address(0), "This loan has no lender");

        uint smth = ((loan.amount * rewardPercentage) / 100);
        payable(loan.lender).transfer(loan.amount + smth);
        payable(loan.loaner).transfer(loan.amount * collateralRatio - smth);

        Loan memory emptyLoan = Loan({
            loaner: address(0),
            lender: address(0),
            amount: 0,
            expiresAt: 0
        });
        loans[msg.sender] = emptyLoan;
    }

    fallback() external payable {}

    receive() external payable {}
}
