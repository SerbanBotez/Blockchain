// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract Project {
    
    struct Manager {
        uint id;
        string name;
        uint reputation;
        address manager_address;
    }
    
    struct Evaluator{
        uint id;
        string name;
        uint reputation;
        address evaluator_address;
        string domain_expertise;
    }
    
    struct Freelancer{
        uint id;
        string name;
        uint reputation;
        address freelancer_address;
        string domain_expertise;
    }
    
    struct Financier{
        uint id;
        string name;
        address financier_address;
        uint tokens_number;
    }
    
    mapping(uint => Manager) public managers;
    uint public managersCount;
    mapping(uint => Financier) public financiers;
    uint public financiersCount;
    mapping(uint => Evaluator) public evaluators;
    uint public evaluatorsCount;
    mapping(uint => Freelancer) public freelancers;
    uint public freelancersCount;
    
    //1.InitMarketPlace
    //1manager2evaluator34financer567freelancer
    // manager
    // /0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    address payable public marketplace;
    
    constructor (){
        addManager("Manager1", 5, 0x8d40457933a5AF57cA76DA53D4984CF982658bBa);
        addEvaluator("Evaluator1", 5, 0x8fd80edc0546471B93F9Ab2c71B750BBab1a22Dd, "IT");
        addFinancier("Financier1", 0x4B65d48c87A343fEfC85b5693713993092c3d696, 3);
        addFinancier("Financier2", 0x7D7479dB66c0e0Bb6454F9843a30B8c353Ed07ab, 4);
        addFreelancer("Freelancer1", 5, 0x71b64647ca88E9416B4aF8d827771cb84a08eB8c, "IT");
        addFreelancer("Freelancer2", 5, 0x34e25a40A492f19ecA7DbBAB6527c1a5DbdD7B26, "IT");
        addFreelancer("Freelancer3", 5, 0xe1A4474E951ef6621a258c05E165c29CdFd077d8, "Music");
        addProduct("ProductDescription", 900, 100, "IT");
        addProduct("ProductDescription", 800, 200, "Sports");
        addProduct("ProductDescription", 1000, 50, "Music");
        marketplace = msg.sender;
    }
    
    function getbalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function addManager (string memory _name, uint _reputation, address _manager_address) private {
        managersCount ++;
        managers[managersCount] = Manager(managersCount, _name, _reputation, _manager_address);
    }
    
    function addFinancier(string memory _name, address _financier_address, uint _tokens_number) private {
        financiersCount ++;
        financiers[financiersCount] = Financier(financiersCount, _name, _financier_address, _tokens_number);
    }
    
    function addEvaluator (string memory _name, uint _reputation, address _evaluator_address, string memory _domain_expertise) private {
        evaluatorsCount ++;
        evaluators[evaluatorsCount] = Evaluator(evaluatorsCount, _name, _reputation, _evaluator_address, _domain_expertise);
    }
    
    function addFreelancer (string memory _name, uint _reputation, address _freelancer_address, string memory _domain_expertise) private {
        freelancersCount ++;
        freelancers[freelancersCount] = Freelancer(freelancersCount, _name, _reputation, _freelancer_address, _domain_expertise);
    }
    
    //2.Creating product
    //workon state modifiers
    
    enum State{NotReached, Reached}
    enum CompletitionState{NotFinished, Finished, Working, Developed}
    
    struct Product{
        uint product_id;
        string description;
        uint dev;
        uint rev;
        string domain_expertise;
        uint id; //Manager
        uint evaluator_id; //Evaluator
        State state;
        uint currentSum; //dev rev 
        CompletitionState compstate;
        uint[] financerSum;
        address[] financerAddress;
        uint[] appliedfreelancersid;
        uint[] appliedfreelancerssum;
        uint[] selectedfreelancers;
        uint freelancerSum;
        bool existedEvaluation;
    }
    
    Product[] public products;
    uint productNumber;
    
    modifier stateNotReached(uint id){
        require(products[id].state == State.NotReached, "The dev + rev sum has already been reached, cannot contribute/withdraw");
        _;
    }
    
    modifier stateReached(uint id){
        require(products[id].state == State.Reached, "The dev + rev sum has not been reached, cannot start product development");
        _;
    }
    
    modifier onlyManager(){
        uint local  = 0;
        
        for(uint i = 1; i <= managersCount; i++)
            if(msg.sender == managers[i].manager_address){
                local = 1;
                break;
            }
            
        require(local == 1, "Only a manager can add/remove products and select freelancers");
        _;
    }
    
    modifier onlyFinancier(){
        uint local  = 0;
        
        for(uint i = 1; i <= financiersCount; i++)
            if(msg.sender == financiers[i].financier_address){
                local = 1;
                break;
            }
            
        require(local == 1, "Only a financier can add/withdraw a sum");
        _;
    }
    
    function addProduct (string memory _description, uint _dev, uint _rev, string memory _domain_expertise) onlyManager public{
        
        uint managerid;
        for(uint i = 1; i <= managersCount; i++){
            if(msg.sender == managers[i].manager_address)
                managerid = managers[i].id;
        }
        
        uint[] storage arr;
        address[] storage addarr;
        uint[]  storage appfreeid;
        uint[] storage appfreesum;
        uint[] storage selfree;
        bool existed = false;
        products.push(Product(productNumber, _description, _dev, _rev, _domain_expertise, managerid, 0,
        State.NotReached, 0, CompletitionState.NotFinished, arr, addarr, appfreeid, appfreesum, selfree, 0, existed));
        productNumber ++;
    }
    
    function financeProduct(uint _sum, uint _id)  payable public stateNotReached(_id) onlyFinancier{
        //Check if dev rev sum doesn't go overboard
        if(products[_id].currentSum + _sum > products[_id].dev + products[_id].rev){
            _sum = products[_id].dev + products[_id].rev - products[_id].currentSum;
        }
        
        //Send sum
        marketplace.transfer(_sum);
        
        //Increment product currentSum
        products[_id].currentSum = products[_id].currentSum + _sum;
        
        //Change product state if currentSum reached
        if(products[_id].currentSum == products[_id].dev + products[_id].rev){
             products[_id].state = State.Reached;
        }
        
        //Add financer to collection in product
        //check if financier addres exists in array, if yes only increment sum array, if not add both address and sum
        for(uint i = 0; i < products[_id].financerAddress.length; i++)
            if(msg.sender == products[_id].financerAddress[i]){
                products[_id].financerSum[i] += _sum;
                return;
            }
            
        products[_id].financerSum.push(_sum);
        products[_id].financerAddress.push(msg.sender);
    }
    
    //if sum reaches 0, financier addres/sum remains in arrays
    function withdrawFinance(uint _sum, uint _id) payable public stateNotReached(_id) onlyFinancier{
        uint i;
        
        for(i = 0; i < products[_id].financerAddress.length; i++){
            if(msg.sender == products[_id].financerAddress[i]){
                if(_sum > products[_id].financerSum[i]){
                    _sum = products[_id].financerSum[i];
                }
                break;
            }
        }
        
        msg.sender.transfer(_sum);
        products[_id].financerSum[i] = products[_id].financerSum[i] - _sum;
        products[_id].currentSum = products[_id].currentSum - _sum;
    }
    
    function getFinanciersSum(uint _id) public view returns (uint[] memory) {
        return products[_id].financerSum;
    }
    
    function getFinanciersAddresses(uint _id) public view returns (address[] memory) {
        return products[_id].financerAddress;
    }
    
    //nmerge, dar cam ciudat(id-ul produsului de pe index 1 dupa ce am sters prod cu index 0 de 2 ori e ciudat)
    function removeProduct(uint _id) public payable stateNotReached(_id) onlyManager{
        for(uint i = 0; i < products[_id].financerAddress.length; i++){
            if(products[_id].financerSum[i] != 0){
                payable(products[_id].financerAddress[i]).transfer(products[_id].financerSum[i]);
            }
        }
        
        //move products change index delete element
        for (uint i = _id; i < products.length - 1; i++){
            products[i] = products[i+1];
            products[i].product_id--;
        }
        delete products[products.length-1];
    }
    
    //3. Applying for products
    modifier onlyEvaluator(){
        uint local  = 0;
        
        for(uint i = 1; i <= evaluatorsCount; i++)
            if(msg.sender == evaluators[i].evaluator_address){
                local = 1;
                break;
            }
            
        require(local == 1, "Only an evaluator can apply for the dispute");
        _;
    }
    
    modifier evaluator_same_domain_expertise(uint _id){
         //address currentAddress = msg.sender;
         address currentAddress = 0x8fd80edc0546471B93F9Ab2c71B750BBab1a22Dd;
         
          for(uint i = 1; i <= evaluatorsCount; i++){
            if(evaluators[i].evaluator_address == currentAddress){
                require(keccak256(abi.encodePacked(products[_id].domain_expertise)) ==
                keccak256(abi.encodePacked(evaluators[i].domain_expertise)), "You must select a product from your domain expertise");
                 _;
            }
          }
    }
    
    modifier already_evaluated(uint _id){
        require(products[_id].evaluator_id == 0, "The product is already evaluated by someone");
        _;
    }
    
    function evaluatorApply(uint _id) public onlyEvaluator evaluator_same_domain_expertise(_id) already_evaluated(_id){
        address currentAddress = msg.sender;
        for(uint i = 1; i <= evaluatorsCount; i++){
            if(evaluators[i].evaluator_address == currentAddress){
                products[_id].evaluator_id = evaluators[i].id;
                break;
            }
        }
    }
    
    modifier onlyFreelancer(){
        uint local  = 0;
        
        for(uint i = 1; i <= freelancersCount; i++)
            if(msg.sender == freelancers[i].freelancer_address){
                local = 1;
                break;
            }
            
        require(local == 1, "Only a freelancer can apply for product development");
        _;
    }
    
    modifier freelancer_same_domain_expertise(uint _id){
         address currentAddress = msg.sender;
         
          for(uint i = 1; i <= freelancersCount; i++){
            if(freelancers[i].freelancer_address == currentAddress){
                require(keccak256(abi.encodePacked(products[_id].domain_expertise)) ==
                keccak256(abi.encodePacked(freelancers[i].domain_expertise)), "You must select a product from your domain expertise");
                 _;
            }
          }
    }  
    
    //the freelancer can apply multiple times, not intended
    function freelancerApply(uint _id, uint _sum) public onlyFreelancer freelancer_same_domain_expertise(_id){
        address currentAddress = msg.sender;
        
        for(uint i = 1; i <= freelancersCount; i++){
            if(freelancers[i].freelancer_address == currentAddress){
                //products[_id].evaluator_id = evaluators[i].id;
                products[_id].appliedfreelancersid.push(freelancers[i].id);
                products[_id].appliedfreelancerssum.push(_sum);
                break;
            }
        }
    }
    
    function getFreelancerSum(uint _id) public view returns (uint[] memory) {
        return products[_id].appliedfreelancerssum;
    }
    
    function getFreelancerId(uint _id) public view returns (uint[] memory) {
        return products[_id].appliedfreelancersid;
    }
    
    //4. Product Development
    //add freelancer, increment sum, check if sum reached total
    //the freelancerSum must be exactly dev
    function addSelectedFreelancer(uint _prodid, uint _freeid) public onlyManager{
        uint i;
        
        for(i = 0; i < products[_prodid].selectedfreelancers.length; i++)
            if(products[_prodid].selectedfreelancers[i] == _freeid)
                break;
                
        if(i == products[_prodid].selectedfreelancers.length)
            products[_prodid].selectedfreelancers.push(_freeid);
        
        for(i = 0; i < products[_prodid].appliedfreelancersid.length; i++){
            if(products[_prodid].appliedfreelancersid[i] == _freeid){
                products[_prodid].freelancerSum = products[_prodid].freelancerSum + products[_prodid].appliedfreelancerssum[i];
                break;
            }
        }
        
        if(products[_prodid].freelancerSum == products[_prodid].dev)
            products[_prodid].compstate = CompletitionState.Working;
            //product can be developed
    }
    
    function getselectedFreelancers(uint _id) public view returns (uint[] memory) {
        return products[_id].selectedfreelancers;
    }
    
    
    //Accepting the work if freelancers did a good job
    //payable functions need wallet
    function acceptProduct(uint _id) public payable onlyManager{
        //sum given to freelancers + increased rep + product marked as finished
        
        for(uint i = 0; i < products[_id].selectedfreelancers.length; i++){
            //id == products[_id].selectedfreelancers[i]
            address payable addr = payable(freelancers[products[_id].selectedfreelancers[i]].freelancer_address);
            uint _sum = 0;
            
            for(uint j = 0; j < products[_id].appliedfreelancersid.length; j++){
                if(products[_id].selectedfreelancers[j] == products[_id].appliedfreelancersid[j]){
                    _sum = products[_id].appliedfreelancerssum[j];
                    break;
                }
            }
            
            addr.transfer(_sum);
            freelancers[products[_id].selectedfreelancers[i]].reputation += 2;
            
            if(freelancers[products[_id].selectedfreelancers[i]].reputation > 10){
                freelancers[products[_id].selectedfreelancers[i]].reputation = 10;
            }
            products[_id].compstate = CompletitionState.Developed;
        }    
    }
    
    //Rejecting the work
    function rejectProduct(uint _id) public payable onlyManager{
        products[_id].existedEvaluation = true;
    }
    
    function evaluatorRejectManagerDecision(uint _id) public payable onlyEvaluator{
         for(uint i = 0; i < products[_id].selectedfreelancers.length; i++){
            //id == products[_id].selectedfreelancers[i]
            address payable addr = payable(freelancers[products[_id].selectedfreelancers[i]].freelancer_address);
            uint _sum = 0;
            
            for(uint j = 0; j < products[_id].appliedfreelancersid.length; j++){
                if(products[_id].selectedfreelancers[j] == products[_id].appliedfreelancersid[j]){
                    _sum = products[_id].appliedfreelancerssum[j];
                    break;
                }
            }
            
            addr.transfer(_sum);
            
            freelancers[products[_id].selectedfreelancers[i]].reputation += 2;
            if(freelancers[products[_id].selectedfreelancers[i]].reputation > 10){
                freelancers[products[_id].selectedfreelancers[i]].reputation = 10;
            }
            
            if(managers[products[_id].id].reputation - 2 < 1){
                managers[products[_id].id].reputation = 0;
            }
            else{
                managers[products[_id].id].reputation -= 2;
            }
        }    
    }
    
    //lower team reputation + delete team
    function evaluatorAcceptManagerDecision(uint _id) public onlyEvaluator{
        uint i;
        for(i = 0; i < products[_id].selectedfreelancers.length; i++){
            
            if(freelancers[products[_id].selectedfreelancers[i]].reputation - 2 < 1){
                freelancers[products[_id].selectedfreelancers[i]].reputation = 0;
            }
            else{
                freelancers[products[_id].selectedfreelancers[i]].reputation -= 2;
            }
            
            delete products[_id].selectedfreelancers[i];
        }
        
        products[_id].freelancerSum = 0;
        
        for(i = 0; i < products[_id].appliedfreelancersid.length; i++){
            delete products[_id].appliedfreelancersid[i];
            delete products[_id].appliedfreelancerssum[i];
        }
    }
    
    //5. Product development Completition
    function completeProduct(uint _id) payable public{
        products[_id].compstate = CompletitionState.Finished;
        
        if(products[_id].existedEvaluation == false){
            //send rev sum to manager
            payable(managers[products[_id].id].manager_address).transfer(products[_id].rev);
            
            
            //increment manager reputation        
            if(managers[products[_id].id].reputation + 2 > 10){
                managers[products[_id].id].reputation = 10;
            }else{
                managers[products[_id].id].reputation += 2;
            }
        }
        else{
            //send rev sum to evaluator
            payable(evaluators[products[_id].id].evaluator_address).transfer(products[_id].rev);
        }
    }
}