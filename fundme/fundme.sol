// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
// its like api link 
import {PriceConverter} from "./PriceConverter.sol";
// import file 

error NotOwner();
// reverts the transaction see below 

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressAndAmountOfFunders;
    // this mapping function connects the address of the funders to the amount of funders funded
    address[] public funderslist;
    // in this array we store the list of funders

    address public  immutable  i_owner;
    // immutable means we cant change the value of the owner 
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    // constant variables should always be in caps 

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You need to spend more ETH!");
        // msg.value is the amount the funder funds
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressAndAmountOfFunders[msg.sender] += msg.value;
        funderslist.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
        // underscore placement matters
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funderslist.length; funderIndex++) {
            address funder = funderslist[funderIndex];
            addressAndAmountOfFunders[funder] = 0;
            // basically makes the address's amount to the zero 
            // only owner can makes this function call 
        }
        funderslist = new address[](0);
        // makes the array to the zero to store the new transactions addresses and amount mapped

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        //shows balance obv
        require(callSuccess, "Call failed");
        // bool - 0 and 1 

        //other two types of calling 
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
    }
   

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
    // two types of recieving eth without funding 
     // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()
}

