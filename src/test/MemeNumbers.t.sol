// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/MemeNumbersTest.sol";
import { Errors } from "../MemeNumbers.sol";

contract Meme is MemeNumbersTest {
    // TODO: ...

    function testForSale() public {
        uint256[] memory forSale = meme.getForSale();

        emit log_named_uint("forSale[0]", forSale[0]);
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

