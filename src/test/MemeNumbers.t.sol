// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/MemeNumbersTest.sol";
import { Errors } from "../MemeNumbers.sol";

contract MemeViewTests is MemeNumbersTest {
    uint256 constant MAX_UINT = 2 ** 256 - 1;

    function testForSale() public {
        (uint256[] memory forSale,) = meme.getForSale();
        assertEq(forSale[0], 87);
        assertEq(forSale[1], 682);
        assertEq(forSale[2], 12117);
        assertEq(forSale[3], 143189);
        assertEq(forSale[4], 10310010);
        assertEq(forSale[5], 2766511441);
        assertEq(forSale[6], 13420811902933346092);
        assertEq(forSale[7], 76233043312742894706265533);
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

        assertEq(meme.balanceOf(address(this)), 8);
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

    function testMintFreeAll() public {
        hevm.warp(1 hours);

        meme.mintAll{ value: 0 }(address(this));

        assertEq(meme.balanceOf(address(this)), 8);
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

    function testBurnSameTwice() public {
        uint256 price = meme.currentPrice();
        (uint256[] memory nums,) = meme.getForSale();
        meme.mintAll{ value: price }(address(this));
        try meme.burn(address(this), nums[1], "d", nums[1]) { fail(); } catch Error(string memory error) {
            assertEq(error, Errors.NoSelfBurn);
        }
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
