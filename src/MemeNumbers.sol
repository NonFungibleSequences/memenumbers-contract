// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./MemeNumbersRenderer.sol";

library Errors {
    string constant AlreadyMinted = "already minted";
    string constant UnderPriced = "current price is higher than msg.value";
    string constant NotForSale = "number is not for sale in this batch";
    string constant MustOwnNum = "must own number to operate on it";
    string constant InvalidOp = "invalid op";
    string constant DoesNotExist = "does not exist";
    string constant RendererUpgradeDisabled = "renderer upgrade disabled";
}

contract MemeNumbers is ERC721, Ownable {
    uint256 public constant AUCTION_START_PRICE = 5 ether;
    uint256 public constant AUCTION_DURATION = 1 hours;
    uint256 public constant BATCH_SIZE = 7;

    uint256 public auctionStarted;
    uint256[BATCH_SIZE] private forSale;

    mapping(uint256 => bool) viaBurn; // Numbers that were created via burn

    /// disableRenderUpgrade is whether we can still upgrade the tokenURI renderer.
    /// Once it is set it cannot be unset.
    bool disableRenderUpgrade = false;
    ITokenRenderer public renderer;

    /// @dev Emitted when the auction batch is refreshed.
    event Refresh(); // TODO: Do we want to include any fields?

    constructor(address _renderer) ERC721("MemeNumbers", "MEMENUM") {
        renderer = ITokenRenderer(_renderer);

        _refresh();
    }

    // Internal helpers:

    function _getEntropy() view internal returns(uint256) {
        // This is not ideal but it's not practical to do a real source of entropy
        // like ChainLink with 2 LINK per refresh shuffle.

        // Borrowed from: https://github.com/1001-digital/erc721-extensions/blob/f5c983bac8989bc5ebf9b34c03f28e438da9a7b3/contracts/RandomlyAssigned.sol#L27
        return uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp,
                blockhash(block.number))));
    }

    /**
     * @dev Generate a fresh sequence available for sale based on the current block state.
     */
    function _refresh() internal {
        auctionStarted = block.timestamp;

        uint256 entropy = _getEntropy();

        // Slice it up with fibonacci bit masks: 5, 8, 13, 21, 34, 55, 89
        // Eligibility is confirmed during isForSale, getForSale, and mint.
        // Eligible batches can be smaller than the forSale batch.
        forSale[0] = (entropy >> 0) & (2 ** 5 - 1);
        forSale[1] = (entropy >> 5) & (2 ** 8 - 1);
        forSale[2] = (entropy >> 8) & (2 ** 13 - 1);
        forSale[3] = (entropy >> 13) & (2 ** 21 - 1);
        forSale[4] = (entropy >> 21) & (2 ** 34 - 1);
        forSale[5] = (entropy >> 34) & (2 ** 55 - 1);
        forSale[6] = (entropy >> 55) & (2 ** 89 - 1);

        emit Refresh();
    }


    // Public views:

    /// @dev The current price of the dutch auction. Winning bids above this price will return the difference.
    function currentPrice() view public returns(uint256) {
        // Linear price reduction from AUCTION_START_PRICE to 0
        uint256 endTime = (auctionStarted + AUCTION_DURATION);
        if (block.timestamp >= endTime) {
            return 0;
        }
        return AUCTION_START_PRICE * ((endTime - block.timestamp) / AUCTION_DURATION);
    }

    /// @dev Return whether a number is for sale and eligible
    function isForSale(uint256 num) view public returns (bool) {
        for (uint256 i=0; i<forSale.length; i++) {
            if (forSale[i] == num) return !_exists(num);
        }
        return false;
    }

    /// @dev Eligible numbers for sale.
    function getForSale() view public returns (uint256[] memory) {
        uint256[] memory r = new uint256[](BATCH_SIZE);
        uint256 count = 0;
        for (uint256 i=0; i<forSale.length; i++) {
            if (_exists(forSale[i])) continue;
            r[count] = forSale[i];
            count += 1;
        }
        return r;
    }

    /// @dev Returns whether num was minted by burning, or if it is an original from auction.
    function isMintedByBurn(uint256 num) view external returns (bool) {
        return viaBurn[num];
    }

    /**
     * @dev Apply a mathematical operation on two numbers, returning the
     *   resulting number. Treat this as a read-only preview of `burn`.
     * @param num1 Number to burn, must own
     * @param op Operation to burn num1 and num2 with, one of: add, sub, mul, div
     * @param num2 Number to burn, must own
     */
    function operate(uint256 num1, string calldata op, uint256 num2) public pure returns (uint256) {
        // FIXME: Check over/underflows
        bytes1 mode = bytes(op)[0];
        if (mode == "a") { // Add
            return num1 + num2;
        }
        if (mode == "s") { // Subtact
            return num1 - num2;
        }
        if (mode == "m") { // Multiply
            return num1 * num2;
        }
        if (mode == "d") { // Divide
            return num1 / num2;
        }
        revert(Errors.InvalidOp);
    }


    // Main interface:

    /**
     * @dev Mint one of the numbers that are currently for sale at the current dutch auction price.
     * @param to Address to mint the number into.
     * @param num Number to mint, must be in the current for-sale sequence.
     *
     * Emits a {Refresh} event.
     */
    function mint(address to, uint256 num) external payable {
        uint256 price = currentPrice();
        require(price <= msg.value, Errors.UnderPriced);
        require(isForSale(num), Errors.NotForSale);

        _mint(to, num);
        _refresh();

        if (msg.value > price) {
            // Refund difference of currentPrice vs msg.value to allow overbidding
            payable(msg.sender).transfer(msg.value - price);
        }

    }

    /**
     * @dev Refresh the auction without minting once the auction price is 0.
     *
     * Emits a {Refresh} event.
     */
    function refresh() external {
        require(currentPrice() == 0, Errors.UnderPriced);
        _refresh();
    }

    /**
     * @dev Burn two numbers together using a mathematical operation, producing
     *   a new number if it is not already taken. No minting fee required.
     * @param to Address to mint the resulting number into.
     * @param num1 Number to burn, must own
     * @param op Operation to burn num1 and num2 with, one of: add, sub, mul, div
     * @param num2 Number to burn, must own
     */
    function burn(address to, uint256 num1, string calldata op, uint256 num2) external {
        require(ownerOf(num1) == _msgSender(), Errors.MustOwnNum);
        require(ownerOf(num2) == _msgSender(), Errors.MustOwnNum);

        uint256 num = operate(num1, op, num2);
        require(!_exists(num), Errors.AlreadyMinted);

        _mint(to, num);
        viaBurn[num] = true;

        _burn(num1);
        _burn(num2);
        delete viaBurn[num1];
        delete viaBurn[num2];
    }


    // Renderer:

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), Errors.DoesNotExist);
        return renderer.tokenURI(IMemeNumbers(address(this)), tokenId);
    }


    // onlyOwner admin functions:

    function adminWithdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    function adminSetRenderer(address _renderer) external onlyOwner {
        require(disableRenderUpgrade == false, Errors.RendererUpgradeDisabled);
        renderer = ITokenRenderer(_renderer);
    }

    function adminDisableRenderUpgrade() external onlyOwner {
        disableRenderUpgrade = true;
    }

}
