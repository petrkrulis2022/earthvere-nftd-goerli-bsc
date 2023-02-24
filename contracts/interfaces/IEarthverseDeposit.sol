// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error EarthverseDeposit_ZeroAddress();
error EarthverseDeposit_NoRETHWasMinted();
error EarthverseDeposit_InvalidDepositAmount();

interface IRocketpool {
  function deposit() external payable;
}

interface IWETH {
  function withdraw(uint256 amount) external;
}
