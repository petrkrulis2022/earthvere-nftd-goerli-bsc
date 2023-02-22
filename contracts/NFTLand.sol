//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/INFTLand.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTLand is INFTLand, ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("NFT Land", "NFTL") {}

  /// @notice Allows the user to mint a nft land
  /// @param ipfsURI: IPFS's link where the img is stored
  function safeMintNFT(
    string calldata ipfsURI
  ) external returns (uint256 newTokenId) {
    newTokenId = _tokenIds.current();

    _safeMint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, ipfsURI);
    _tokenIds.increment();
  }
}
