//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract NFTDollar is ERC20Burnable, Ownable {
  constructor() ERC20("NFT Dollar", "NFTD") {}

  function mint(address to, uint256 amount, uint256 decimalsOfInput) external {
    _mint(to, amount * 10 ** (18 - decimalsOfInput));
  }
}
