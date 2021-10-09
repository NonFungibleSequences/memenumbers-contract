// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/MemeNumbersTest.sol";
import { Errors } from "../MemeNumbers.sol";

contract MemeViewTests is MemeNumbersTest {
    uint256 constant MAX_UINT = 2 ** 256 - 1;
    function testForSale() public {
        (uint256[] memory forSale,) = meme.getForSale();
        assertEq(forSale[0], 23);
        assertEq(forSale[1], 170);
        assertEq(forSale[2], 3925);
        assertEq(forSale[3], 1921402);
        assertEq(forSale[4], 7061478737);
        assertEq(forSale[5], 18099411878749996);
        assertEq(forSale[6], 308346800678751696249851325);
    }

    function testPrice() public {
        assertEq(meme.currentPrice(), 5 ether);

        hevm.warp(12 minutes); // 1/5
        assertEq(meme.currentPrice(), 4 ether);

        hevm.warp(36 minutes);
        assertEq(meme.currentPrice(), 2 ether);

        hevm.warp(2 hours);
        assertEq(meme.currentPrice(), 0 ether);
    }

    function testOperate() public {
        assertEq(meme.operate(42, "sub", 41), 1);
        assertEq(meme.operate(2, "mul", 3), 6);

        assertEq(meme.operate(10, "div", 5), 2);
        assertEq(meme.operate(1, "div", 3), 0); // div into zero -- FIXME: Is this desirable?
        assertEq(meme.operate(10, "div", 3), 3); // div rounding

        // Overflows/underflows
        try meme.operate(MAX_UINT, "mul", 2) { fail(); } catch Panic(uint) {} // mul overflow
        try meme.operate(5, "sub", 6) { fail(); } catch Panic(uint) {} // sub underflow
        try meme.operate(MAX_UINT, "add", 42) { fail(); } catch Panic(uint) {} // add overflow
    }
}

contract MemeMintTests is MemeNumbersTest {
    receive() external payable {}

    function testMintOverbid() public {
        uint256 startingBalance = address(this).balance;

        uint256 price = meme.currentPrice();
        assertEq(price, 5 ether);

        (uint256[] memory forSale,) = meme.getForSale();
        meme.mint{ value: 8 ether }(address(this), forSale[1]);

        assertEq(address(this).balance, startingBalance - 5 ether); // X-5 despite sending 8 ether
    }

    function testMintAll() public {
        uint256 price = meme.currentPrice();
        meme.mintAll{ value: price }(address(this));

        assertEq(meme.balanceOf(address(this)), 7);
    }

    function testMint() public {
        uint256 price = meme.currentPrice();
        (uint256[] memory forSale,) = meme.getForSale();
        meme.mint{ value: price }(address(this), forSale[1]);

        assertEq(meme.ownerOf(forSale[1]), address(this));
    }

    function testMintFree() public {
        hevm.warp(1 hours);

        (uint256[] memory forSale,) = meme.getForSale();
        meme.mint{ value: 0 }(address(this), forSale[1]);

        assertEq(meme.ownerOf(forSale[1]), address(this));
    }

}

contract MemeBurnTests is MemeNumbersTest {
    receive() external payable {}

    function testAdd() public {
        uint256 price = meme.currentPrice();
        (uint256[] memory nums,) = meme.getForSale();
        meme.mintAll{ value: price }(address(this));

        try meme.ownerOf(nums[1] + nums[2]) { fail(); } catch Error(string memory error) {
            assertEq(error, "ERC721: owner query for nonexistent token");
        }
        meme.burn(address(this), nums[1], "add", nums[2]);
        assertEq(meme.ownerOf(nums[1] + nums[2]), address(this));

        assert(!meme.isMintedByBurn(nums[3]));
        assert(meme.isMintedByBurn(nums[1] + nums[2]));
    }

    function testMul() public {
        uint256 price = meme.currentPrice();
        (uint256[] memory nums,) = meme.getForSale();
        meme.mintAll{ value: price }(address(this));
        meme.burn(address(this), nums[1], "m", nums[2]);
        assertEq(meme.ownerOf(nums[1] * nums[2]), address(this));
    }
}

contract MemeIntegrationTests is MemeNumbersTest {
    function testMint() public {
        payable(address(alice)).transfer(100 ether);

        try alice.mint(1) { fail(); } catch Error(string memory error) {
            assertEq(error, Errors.NotForSale);
        }

        (uint256[] memory forSale,) = meme.getForSale();
        alice.mint(forSale[0]);

        assertEq(meme.ownerOf(forSale[0]), address(alice));
    }
}

contract HelperTests is DSTest {
    // Confirming solidity mechanics

    function testArrayResize() public {
        uint256[] memory r = new uint256[](7);
        r[0] = 42;
        r[1] = 69;

        assertEq(r.length, 7);
        assertEq(r[2], 0);

        uint256[] memory resized = new uint256[](2);
        resized = r; // Was hoping this would truncate to the resized length but it does not.

        assertEq(resized.length, 7);
        assertEq(resized[2], 0);
    }
}
