// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract DistributeFunding{
    
    mapping(address => uint) public shareholders;
    address payable[] public shareholderAddresses;
    uint[] public shareholdersBalances;
    
    fallback() external payable {
        // custom function code
    }

    receive() external payable {
    }

    function getbalance() public view returns (uint){
        return address(this).balance;
    }
    
    function addShareholder(address payable _address, uint _share) public{
        shareholders[_address] = _share;
        shareholderAddresses.push(_address);
    }
    
    function distributeSum(uint sum) payable public{
        for(uint i = 0; i < shareholderAddresses.length; i++){
            shareholderAddresses[i].transfer((sum * shareholders[shareholderAddresses[i]])/ 100);
        }
    }
    
    function getShareholdersBalances() public returns(uint[] memory){
         for(uint i = 0; i < shareholderAddresses.length; i++) {
             shareholdersBalances.push(shareholderAddresses[i].balance);
         }
         return shareholdersBalances;
    }
}