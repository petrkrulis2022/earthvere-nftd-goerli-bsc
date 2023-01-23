//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTLandToken {
  function mint(
    address to,
    string memory tokenURI
  ) external payable returns (uint256);
}
