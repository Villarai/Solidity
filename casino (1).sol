pragma solidity 0.8.18;

contract Casino
{
    uint govDone;    //count the times that government takes part in RNG
    uint rngPlayers; //count the numbers of all the rng participants
    address payable public gov=payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4); //hard code of government's public key
    uint depositAmount = 1000 ether; //the amount of deposit that the casino should pay
    uint value;  //record the amount of money the casino has paid
    bool depositFlag = false;   //whether the casino has pay the deposit
    uint [16] randomNum = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
    mapping (uint => address) rngPlayer;
    mapping (uint => uint[]) randNumRecord;
    bool rngFlag = false;
    mapping (uint => address) gambler;
    uint gamblers;
    mapping (uint => uint) gambleNum;
    address payable public owner;
    mapping (uint => bool) resultUpdated;   //whether the casino has updated the result of game with gambler i
    mapping (uint => uint) result;  //0 if the the bettor wins, 1 if the bettor loses, 2 if the bettor is refunded or the casino didn't announce the result after due
    mapping (uint => uint) time;
    uint due = 2 hours;
    bool casinoCheated;
    uint r;
    uint T=1 days;


    constructor() 
    {
        require(tx.origin==msg.sender);
        owner=payable (msg.sender);
    }


    function RNG(uint[] memory num) public 
    {
        require(!rngFlag);
        require(num.length==16);
        rngPlayers++;
        if(govDone<(rngPlayers/2+1))    //whenever the gov terminates the rng, there's always more than half inputs come from them
        {
            require(msg.sender==gov);
        }
        if(msg.sender==gov){
            govDone++;
        }

        rngPlayer[rngPlayers-1]=tx.origin;
        randNumRecord[rngPlayers-1]=num;

        for (uint i=0; i<16; i++){
            randomNum[i]*=num[i];
        }

    }

    function governStopRng(uint[] memory M) public  //gov terminate the rng and give casino random number M
    {
        require(msg.sender==gov);
        require(rngPlayer[rngPlayers-1]!=gov);  //ensure there's at lease one player does not belong to the gov
        require(!rngFlag);
        rngPlayers++;
        govDone++;
        rngPlayer[rngPlayers-1]=gov;
        randNumRecord[rngPlayers-1]=M;
        for (uint i=0; i<16; i++){
            randomNum[i]*=M[i];
        }
        rngFlag=true;
    }

    function deposit() public payable 
    {
        value+=uint(msg.value);
        if(value>=depositAmount)
        {
            depositFlag = true;
        }
    }

    function gamble(uint k) public payable 
    {
        require(msg.value==0.01 ether);
        gamblers++;
        gambler[gamblers-1]=tx.origin;
        gambleNum[gamblers-1]=k;
        time[gamblers-1]=block.timestamp;
    }

    function reportRepeatedNum(uint i, uint j) public 
    {
        require(!resultUpdated[j]); //The function can be called only once. And it's the casino's own responsibility to call this function before it pays the bettor, if the reused number is a "winning number"
        require(msg.sender==owner);
        require(i<j);
        require(gambleNum[i]==gambleNum[j]);    //gambler j was using a number that has been used before
        resultUpdated[j]=true;
        result[j]=2;
        address payable receiver = payable (gambler[j]);
        receiver.send(0.01 ether);
        
    }

    function announce(uint nounce, uint i) public 
    {
        require(msg.sender==owner);
        require(!resultUpdated[i]);
        require(nounce==0||nounce==1);
        resultUpdated[i]=true;
        result[i]=nounce;
        if(nounce==0)
        {
            address payable receiver = payable (gambler[i]);
            receiver.send(0.02 ether);
        }


    }

    function overTime(uint i) public 
    {
        require((block.timestamp-time[i])>due);
        require(!resultUpdated[i]);
        resultUpdated[i]=true;
        result[i]=2;
        address payable receiver = payable (gambler[i]);
        receiver.send(0.02 ether);
    }

    function rngVerificationFailed(uint i) public
    {
        require(msg.sender==gov);
        casinoCheated=true;
        gov.transfer(this.balance);
        r=i;
    }

    function rngVerificationPassed(uint i) public 
    {
        require(msg.sender==gov);
        r=i;
    }

    function cheatingFromCasinoDuringGambling(uint r, uint k) public 
    {
        uint s=rand(r+gambleNum[k]);
        if((s%2==0)&&result[k]==1)
        {
            casinoCheated=true;
            gov.transfer(this.balance);
        }
    }

    function collect() public 
    {
        require((block.timestamp-time[0])>T);
        if(!casinoCheated)
        {
            owner.transfer(this.balance);
        }
    }

}