// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/MemeNumbersTest.sol";
import { Errors } from "../MemeNumbers.sol";

contract MemeState is MemeNumbersTest {
    function testForSale() public {
        uint256[] memory forSale = meme.getForSale();
        assertEq(forSale[0], 23);
        assertEq(forSale[1], 170);
        assertEq(forSale[2], 3925);
        assertEq(forSale[3], 1921402);
        assertEq(forSale[4], 7061478737);
        assertEq(forSale[5], 18099411878749996);
        assertEq(forSale[6], 308346800678751696249851325);
    }

    function testPrice() public {
        uint256 price = meme.currentPrice();
        assertEq(price, 5 ether);
    }
}

contract MemeMint is MemeNumbersTest {

    receive() external payable {}

    function testMintOverbid() public {
        uint256 startingBalance = address(this).balance;

        uint256 price = meme.currentPrice();
        assertEq(price, 5 ether);

        uint256[] memory forSale = meme.getForSale();
        meme.mint{ value: 8 ether }(address(this), forSale[1]);

        assertEq(address(this).balance, startingBalance - 5 ether); // X-5 despite sending 8 ether
    }

    function testMint() public {
        payable(address(alice)).transfer(100 ether);

        try alice.mint(1) { fail(); } catch Error(string memory error) {
            assertEq(error, Errors.NotForSale);
        }

        uint256[] memory forSale = meme.getForSale();
        alice.mint(forSale[0]);

        assertEq(meme.ownerOf(forSale[0]), address(alice));
    }
}

