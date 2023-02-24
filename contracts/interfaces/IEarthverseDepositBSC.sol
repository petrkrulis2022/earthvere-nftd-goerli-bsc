// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error EarthverseDeposit_ZeroAddress();
error EarthverseDeposit_NoBNBXWasMinted();
error EarthverseDeposit_InvalidDepositAmount();

interface IStaderStake {
  function deposit() external payable;
}
