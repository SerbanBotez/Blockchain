// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./DistributeFunding.sol";

contract CrowdFunding{
    
    address payable owner;
    address payable distributeFundingAdress;
    uint public fundingGoal;
    uint public currentFunding;
    enum State{NotReached, Reached}
    State state;
    
    mapping(address => uint) contributors;
    address[] public contributorsaddresses;
    uint countContributors = 0;
  
    constructor(address payable _distributeFundingAdress){
        distributeFundingAdress = _distributeFundingAdress;
        currentFunding = 0;
        fundingGoal = 1000;
        owner = msg.sender;
        state = State.NotReached;
    }
    
    modifier onlyOwner(){
         require(msg.sender == owner, "Only the owner can distribute the funds");
        _;
    }
    
    modifier stateNotReached(){
        require(state == State.NotReached, "The funding sum has already been reached, cannot contribute/withdraw");
        _;
    }
    
    modifier stateReached(){
        require(state == State.Reached, "The funding sum has not been reached yet, cannot send sum");
        _;
    }
    
    fallback() external payable {
    }

    receive() external payable {
    }
    
    function getState() public view returns(string memory){
            if(state == State.NotReached)
                return "funding not reached";
     
        return "funding reached";       
    }

    function getbalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function submitSum(uint sum) payable public stateNotReached{
        
        //verifica daca suma ce trebuie adaugata ar face currentFunding sa treaca peste fundingGoal
        if(currentFunding + sum > fundingGoal){
            sum = fundingGoal - currentFunding;
        }
        
        //verifica daca contribuitorul a mai adaugat o suma inainte, incrementarea se face doar pe contribuitori unici
        if(contributors[msg.sender] == 0){
            countContributors = countContributors + 1;
        }
        
        owner.transfer(sum);
        
        contributors[msg.sender] = contributors[msg.sender] + sum;
        currentFunding = currentFunding + sum;
        
        if(currentFunding == fundingGoal){
            state = State.Reached;
        }
        
        for(uint i = 0; i < contributorsaddresses.length; i++){
            if(contributorsaddresses[i] == msg.sender)
                return;
        }
        
        contributorsaddresses.push(msg.sender);
    }
    
    function withdrawSum(uint sum) payable public stateNotReached{
        //cazul in care nu se poate extrage suma data ca parametru
        if(sum > contributors[msg.sender]){
            sum = contributors[msg.sender];
        }
        
        msg.sender.transfer(sum);
        contributors[msg.sender] = contributors[msg.sender] - sum;
        currentFunding = currentFunding - sum;
        
        //verificam daca contribuitorul a ajuns la 0 cu suma depusa, decrementam counterul 
        if(contributors[msg.sender] == 0 && countContributors != 0){
            countContributors = countContributors - 1;
        }
    }
    
    function sendFunding() public stateReached payable onlyOwner{
        distributeFundingAdress.transfer(fundingGoal);
    }
    
    
    function distributeFunds() public payable onlyOwner{
        DistributeFunding distributeFunding = new DistributeFunding();
        distributeFunding.distributeSum(fundingGoal);
        currentFunding = currentFunding - fundingGoal;
        
        state = State.NotReached;
        
        for(uint i = 0; i < contributorsaddresses.length; i++){
            contributors[contributorsaddresses[i]] = 0;
        }
    }
    
}