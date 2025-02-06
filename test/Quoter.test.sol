pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Quoter} from "../src/Quoter.sol";

contract QuoterTest is Test {
    Quoter public quoter;

    function setUp() public {
        quoter = new Quoter();
    }

    function test_quoteExactInput() public {
        uint256 amountIn = 1000000e18;
        uint256 amountOut = quoter.quoteExactInputSingle(
            0x723bc1e6A921e8A6Eddb2CC23Cf89Ae93a212A17,
            true,
            amountIn,
            0
        );
        console.log("amountOut", amountOut);
    }
}
