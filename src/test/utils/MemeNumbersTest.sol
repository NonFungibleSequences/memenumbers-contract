// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "ds-test/test.sol";

import "../../MemeNumbers.sol";
import "../../MemeNumbersRenderer.sol";
import "./Hevm.sol";

contract User {
    MemeNumbers internal meme;

    constructor(address _meme) {
        meme = MemeNumbers(_meme);
    }

    function mint(uint256 num) public {
        uint256 price = meme.currentPrice();
        meme.mint{ value: price }(address(this), num);
    }
}

contract MemeNumbersTest is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // contracts
    MemeNumbers internal meme;
    MemeNumbersRenderer internal renderer;

    // users
    User internal owner;
    User internal alice;
    User internal bob;

    function setUp() public virtual {
        renderer = new MemeNumbersRenderer();
        meme = new MemeNumbers(address(renderer));

        owner = new User(address(meme));
        alice = new User(address(meme));
        bob = new User(address(meme));

        meme.transferOwnership(address(owner));
    }
}
