//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';

import "base64/base64.sol";

interface IMemeNumbers{
}

interface ITokenRenderer {
    function tokenURI(IMemeNumbers instance, uint256 tokenId) external view returns (string memory);
}

contract MemeNumbersRenderer is ITokenRenderer {
  using Strings for uint;

  function renderNFTImage(IMemeNumbers instance, uint256 tokenId) public view returns (string memory) {
    return Base64.encode(bytes(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidyMid meet" viewBox="0 0 400 400" style="background:#00000">',
        '<text x="200" y="200" style="text-anchor:middle;dominant-baseline:middle;fill:white;font-size:24px;">',
          tokenId.toString(),
        '</text>',
      '</svg>')));
  }

  function _generateAttributes(uint256 tokenId) internal pure returns (string memory) {
    string memory parity = "Odd";
    if (tokenId % 2 == 0) {
      parity = "Even";
    }

    uint256 i = tokenId;
    uint256 digits = 0;
    while (i != 0) {
      digits++;
      i /= 10;
    }

    return string(abi.encodePacked(
      '[',
         '{',
            '"trait_type": "Digits",',
            '"value": ', digits.toString(),
          '},',
          '{',
              '"trait_type": "Parity",',
              '"value": ', parity,
          '},',
      ']'
    ));
  }

  function tokenURI(IMemeNumbers instance, uint256 tokenId) public view override(ITokenRenderer) returns (string memory) {
    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(bytes(abi.encodePacked(
              '{"name":"MemeNumber #', tokenId.toString(), '"',
              ',"description":"What is your meme number?"', // FIXME: Write something better
              ',"external_url":"https://memenumbers.com"',
              ',"image":"data:image/svg+xml;base64,', renderNFTImage(instance, tokenId), '"',
              ',"attributes":', _generateAttributes(tokenId),
              '}'
        )))
      )
    );
  }
}
