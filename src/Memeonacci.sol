// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library Errors {
    string constant AlreadyMinted = "already minted";
    string constant UnderPriced = "current price is higher than msg.value";
    string constant NotForSale = "number is not for sale in this batch";
    string constant MustOwnNum = "must own number to operate on it";
    string constant InvalidOp = "invalid op";
    string constant DoesNotExist = "does not exist";
}

contract Memeonacci is ERC721, Ownable {
    uint256 constant AUCTION_START_PRICE = 1 ether;
    uint256 constant AUCTION_DURATION = 2 hours;

    uint256 auctionStarted;
    uint256[] forSale;

    constructor() ERC721("Memeonacci Numeric Sequence", "MEMENUM") {
        refresh();
    }

    // Private helpers:

    /**
     * @dev Generate a fresh sequence available for sale based on the current block state.
     */
    function refresh() private {
        auctionStarted = block.timestamp;

        // XXX: Implement some RNG goodness here.
        forSale = uint256[](123, 456, 789, 1000);
    }


    // Public views:

    function currentPrice() view public returns(uint256) {
        // Linear price reduction from AUCTION_START_PRICE to 0
        uint256 endTime = (auctionStarted + AUCTION_DURATION);
        if (block.now >= endTime) {
            return 0;
        }
        return AUCTION_START_PRICE * ((block.now - endTime) / AUCTION_DURATION);
    }

    function isForSale(uint256 num) view public bool {
        for (uint256 i=0; i<forSale.length; i++) {
            if (forSale[i] == num) return true;
        }
        return false;
    }

    /**
     * @dev Apply a mathematical operation on two numbers, returning the
     *   resulting number. Treat this as a read-only preview of `burn`.
     * @param op Operation to burn num1 and num2 with, one of: add, sub, mul, div
     * @param num1 Number to burn, must own
     * @param num2 Number to burn, must own
     */
    function operate(uint256 num1, string calldata op, uint256 num2) pure returns (uint256) {
        if (op == "add") {
            return num1 + num2;
        }
        if (op == "sub") {
            return num1 - num2;
        }
        if (op == "mul") {
            return num1 * num2;
        }
        if (op == "div") {
            return num1 / num2;
        }
        revert(Errors.InvalidOp);
    }


    // Main interface:

    /**
     * @dev Mint one of the numbers that are currently for sale at the current dutch auction price.
     * @param to Address to mint the number into.
     * @param num Number to mint, must be in the current for-sale sequence.
     */
    function mint(address to, uint256 num) external payable {
        require(!_exists(num), Errors.AlreadyMinted);
        require(currentPrice() <= msg.value, Errors.UnderPriced);
        require(isForSale(num), Errors.NotForSale);

        _mint(to, num);
    }

    /**
     * @dev Burn two numbers together using a mathematical operation, producing
     *   a new number if it is not already taken. No minting fee required.
     * @param to Address to mint the resulting number into.
     * @param num1 Number to burn, must own
     * @param op Operation to burn num1 and num2 with, one of: add, sub, mul, div
     * @param num2 Number to burn, must own
     */
    function burn(address to, uint256 num1, string calldata op, uint256 num2) {
        require(ownerOf(num1) == _msgSender(), Errors.MustOwnNum);
        require(ownerOf(num2) == _msgSender(), Errors.MustOwnNum);

        uint256 num = operate(op, num1, num2);
        require(!_exists(num), Errors.AlreadyMinted);

        _mint(to, num);
    }


    // Renderer:

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), Errors.DoesNotExist);
        // XXX: Implement a renderer, probably as a separate upgradeable thing
        return "data:application/json;{}";
    }


    // onlyOwner admin functions:

    function withdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

}
