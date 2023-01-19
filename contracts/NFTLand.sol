//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTLand is ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter tokenIds;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  function mint(address to) public payable returns (uint256) {
    uint256 newTokenId = tokenIds.current();
    _mint(to, newTokenId);
    _setTokenURI(
      newTokenId,
      "https://ipfs.io/ipfs/QmRiunVjjk3dfr8dzTHVN5m5iJbA411cGRtXtSZxT3vPQM"
    );
    tokenIds.increment();

    return newTokenId;
  }
}
