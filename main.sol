//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract SmartWallet{
  
    struct Transaction{
        uint amount;
        uint timestamp;
    }

    struct Balance {
        uint totalBalance;
        uint numDeposits;
        mapping(uint => Transaction) deposits;
        uint numWithdrawal;
        mapping(uint => Transaction) withdrawals;
    }

    address owner;
    address payable nextOwner;
    uint guardianResetCount;
    uint public constant confirmationsFromGuardiansForRest = 3;
    mapping(address => Balance) balances;
    mapping(address => bool) isAllowedToSend;
    mapping(address => uint) allowance;
    mapping(address => bool) guardians;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVotedBool;

    constructor(){
        owner = msg.sender;
    }

    function setGuardian(address _guardian, bool _isGuardian) public{
        require(msg.sender == owner, "Only owner is allowed to use this function");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public{
        require(guardians[msg.sender], "You are not a gurading of this wallet, aborting");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false, "You have already voted, aborting");
        if(_newOwner != nextOwner){
            nextOwner = _newOwner;
            guardianResetCount = 0;
        }

        guardianResetCount++;

        if(guardianResetCount >= confirmationsFromGuardiansForRest){
            owner = nextOwner;
            nextOwner = payable(address(0));
        }

    }

    function deposit() public payable {
        balances[msg.sender].totalBalance += msg.value;
        balances[msg.sender].numDeposits++;
        Transaction memory cashIn = Transaction(msg.value, block.timestamp);
        balances[msg.sender].deposits[balances[msg.sender].numDeposits] = cashIn;
    }

    function setAllowance(address _address, uint _amount) public {
        require(msg.sender == owner, "Only Admin is allowed to use this function");
        isAllowedToSend[_address] = true;
        allowance[_address] = _amount;

    }

    function MasterWithdrawal(address _address, uint _amount) public {
        require(msg.sender == owner, "Only Admin is allowed to use this function");
        payable(_address).transfer(_amount);
    }

    // function withdraw(address _address, uint _amount) public{
    //     require(isAllowedToSend[msg.sender] && _amount <= allowance[msg.sender], "You are euther not allowed to withdraw, or you are exceeding your allowance limit");
    //     payable(_address).transfer(_amount);
    //     balances[msg.sender].numWithdrawal++;
    //     Transaction memory cashOut = Transaction(_amount, block.timestamp);
    //     balances[msg.sender].withdrawals[balances[msg.sender].numWithdrawal] = cashOut;
    // }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory){
        if(msg.sender != owner){
            require(isAllowedToSend[msg.sender], "You are not in the allowance list, plz check back later or submit an application.");
            require(allowance[msg.sender] > _amount, "You are trying to send more than your allowance limit. aborting.");

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success, "Call was not successfull, aborting.");
        return returnData;
    }

    function getDeposits(address _from, uint _numDeposit) public view returns(Transaction memory){
        return balances[_from].deposits[_numDeposit];
    }

    function getWithdrawals(address _from, uint _numWithdrawal) public view returns(Transaction memory){
        return balances[_from].withdrawals[_numWithdrawal];
    }


    receive() external payable{
        deposit();
    }
    fallback() external payable{
        deposit();
    }
}

contract tester{

    uint public balance;

    function here() public payable {
        balance += msg.value;
    }

    fallback() external payable{
        here();
    }
}
