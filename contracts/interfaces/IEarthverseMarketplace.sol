// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IEarthverseMarketplace {
  function buyNFTLand(
    address buyer,
    uint256 tokenId,
    uint256 price,
    uint256 decimalsOfInput
  ) external returns (address);
}
