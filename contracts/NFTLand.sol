//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/INFTLandToken.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @notice TODO
contract NFTLand is INFTLandToken, ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter tokenIds;

  constructor() ERC721("NFT Land", "NFTL") {}

  /// @notice TODO
  /// @param to: TODO
  /// @param tokenURI: TODO
  function mint(
    address to,
    string memory tokenURI
  ) external payable returns (uint256) {
    uint256 newTokenId = tokenIds.current();

    _safeMint(to, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    tokenIds.increment();

    return newTokenId;
  }
}
