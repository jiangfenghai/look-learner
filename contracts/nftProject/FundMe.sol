// SPDX-License-Identifier: MIT
pragma solidity  0.8.28;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
contract  FundMe {
/*
提交交易
广播交易
达成共识
*/
//1.创建一个收款函数
//2.记录投资人并且查看
//3.在锁定期内，达到摸标志生厂商可以提款
//4.在锁定期以内,没有到达目标值，投资人在锁定期以后退款
//将eth转化成美元

    AggregatorV3Interface internal dataFeed;

    mapping(address => uint256)   public   fundsToAmount;
    uint256 constant   MINMUN_VALUE =  100 *  10**18; //USD
    uint256  constant  TARGET = 1000 * 10 **18;
    address  public owner;
    uint256  deployTime ;
    uint256  endTime;
  

   mapping(uint256 => uint256) public  ethToUsdPrice;
   constructor( uint256 _endTime){
    dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

    owner = msg.sender;
    deployTime = block.timestamp;
    endTime = _endTime + block.timestamp;
   }
    function fund() external   payable {
       require(block.timestamp > deployTime && block.timestamp <  endTime, "This fund is either not started or has already ended.");
        require(converEthToUsd(msg.value) >  MINMUN_VALUE ,"this amount less ");
        fundsToAmount[msg.sender] = msg.value +  fundsToAmount[msg.sender];
    }

    //将eth转化成美元
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }
    //计算eth价格
    function converEthToUsd(uint256 amount) public    returns(uint256){
      //usd价格等于 数量乘以价格
      uint256 priceEth =  uint256(getChainlinkDataFeedLatestAnswer());
      ethToUsdPrice[amount] = priceEth;
      return     amount  * priceEth / (10 **8);      
    }

     function  getFund() external  {
        require(converEthToUsd(address(this).balance) >= TARGET ,"you are not get target");
        require( block.timestamp >  endTime,"this fund not end" );
        require( owner == msg.sender,"this is function call only owner");
        /*
        //转账方式
        //1.transfer
        //2.send
        //3.call
        */
        //1.transter
        payable(msg.sender).transfer(address(this).balance);
     }
     function refund() external  windowClose {
       require(converEthToUsd(address(this).balance ) < TARGET,"this is get target");
       require(fundsToAmount[msg.sender] !=0,"you are not fund");
       require (block.timestamp > deployTime && block.timestamp < endTime , "this fund is not start or  end");
       bool success;
       (success ,) = payable(msg.sender).call{ value : fundsToAmount[msg.sender]}("");
        require(success,"tx has failed");
     }
     /*
        相当于将面向切面编程aop(不改变如何逻辑代码)
     */
     modifier  windowClose(){
         require (block.timestamp > deployTime && block.timestamp < endTime , "this fund is not start or  end");
         _;
     }
}