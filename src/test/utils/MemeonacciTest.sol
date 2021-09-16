// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "ds-test/test.sol";

import "../../Memeonacci.sol";
import "./Hevm.sol";

contract MemeonacciTest is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // TODO: ...
    function setUp() public virtual {
        // ...
    }
}
