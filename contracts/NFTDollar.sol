//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/INFTDollar.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @notice
contract NFTDollar is INFTDollar, ERC20Burnable {
  constructor() ERC20("NFT Dollar", "NFTD") {}

  /// @notice TODO
  /// @param to: TODO
  /// @param amount: TODO
  /// @param decimalsOfInput: TODO
  function mint(address to, uint256 amount, uint256 decimalsOfInput) external {
    _mint(to, amount * 10 ** (18 - decimalsOfInput));
  }
}
