// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/MemeonacciTest.sol";
import { Errors } from "../Memeonacci.sol";

contract Meme is MemeonacciTest {
    // TODO: ...

    function testMint() public {
        try alice.mint(1) { fail(); } catch Error(string memory error) {
            assertEq(error, Errors.NotForSale);
        }

        uint256[] memory forSale = meme.getForSale();
        alice.mint(forSale[0]);

        assertEq(meme.ownerOf(forSale[0]), address(alice));
    }
}

