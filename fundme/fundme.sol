// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();
// reverts the contract see below lines 

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressAndAmountofFunders;
    // adress is mapped to the aount the funders sent 
    address[] public funderslist;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public  immutable  i_owner;
    // words says it bro , immutable cant change value 
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    // const vars should be caps 

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressAndAmountofFunders[msg.sender] += msg.value;
        // msg.value is the input value 
        funderslist.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }
    // this version code is not needed for the transaction but it is used to get the verison of the smart contract
    // the value is being taken

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        // only owner can call this function 
        for (uint256 funderIndex = 0; funderIndex < funderslist.length; funderIndex++) {
            address funder = funderslist[funderIndex];
            addressAndAmountofFunders[funder] = 0;
        }
        funderslist = new address[](0);
        //make the address and amount value zero bcoz we withdrew right
        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
        // other two types of calling functions
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
    // if funders send eth withut calling fund these two methods are used 
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

