// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/MemeNumbersTest.sol";
import { Errors } from "../MemeNumbers.sol";

contract Meme is MemeNumbersTest {
    // TODO: ...

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

