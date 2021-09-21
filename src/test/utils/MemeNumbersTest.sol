// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "ds-test/test.sol";

import "../../MemeNumbers.sol";
import "./Hevm.sol";

contract User {
    MemeNumbers internal meme;

    constructor(address _meme) {
        meme = MemeNumbers(_meme);
    }

    function mint(uint256 num) public {
        meme.mint(address(this), num);
    }
}

contract MemeNumbersTest is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // contracts
    MemeNumbers internal meme;

    // users
    User internal owner;
    User internal alice;

    function setUp() public virtual {
        meme = new MemeNumbers();
        owner = new User(address(meme));
        alice = new User(address(meme));
        meme.transferOwnership(address(owner));
    }
}
