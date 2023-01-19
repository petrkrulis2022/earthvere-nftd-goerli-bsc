//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTDollar {
  function mint(address to, uint256 amount, uint256 decimalsOfInput) external;
}
