// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "ds-test/test.sol";

import "../../Memeonacci.sol";
import "./Hevm.sol";

contract User {
    Memeonacci internal meme;

    constructor(address _meme) {
        meme = Memeonacci(_meme);
    }

    function mint(uint256 num) public {
        meme.mint(address(this), num);
    }
}

contract MemeonacciTest is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // contracts
    Memeonacci internal meme;

    // users
    User internal owner;
    User internal alice;

    function setUp() public virtual {
        meme = new Memeonacci();
        owner = new User(address(meme));
        alice = new User(address(meme));
        meme.transferOwnership(address(owner));
    }
}
