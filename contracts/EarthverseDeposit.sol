//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/INFTDollar.sol";
import "./interfaces/IEarthverseMarketplace.sol";
import "./interfaces/IEarthverseDeposit.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EarthverseDeposit {
  address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
  address public constant RETH = 0x178E141a0E3b34152f73Ff610437A7bf9B83267A;
  address public constant ROCKET_POOL_DEPOSIT =
    0x2cac916b2A963Bf162f076C0a8a4a8200BCFBfb4;

  uint24 public constant POOL_FEE = 3000;

  address public immutable nftd;
  address public immutable earthverseMarketplace;
  ISwapRouter public immutable swapRouter;

  mapping(address => uint256) public balances;

  event StakedAndReceivedNFTLand(
    address indexed sender,
    uint256 indexed amountOut
  );

  constructor(address _nftd, address _earthverseMarketplace) {
    if (_nftd == address(0) || _earthverseMarketplace == address(0))
      revert EarthverseDeposit_ZeroAddress();

    nftd = _nftd;
    earthverseMarketplace = _earthverseMarketplace;
    swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  }

  /// @notice swapExactInputSingle swaps a fixed amount of stablecoin for a maximum possible amount of WETH
  /// using the stablecoin/WETH 0.3% pool by calling `exactInputSingle` in the swap router.
  /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its stablecoin for this function to succeed.
  /// @param amountIn The exact amount of stablecoin that will be swapped for WETH.
  /// @param tokenIn: Stablecoin's address, which we will swap fro WETH.
  /// @return amountOut The amount of WETH received.
  function swapExactInputSingle(
    uint256 amountIn,
    address tokenIn
  ) private returns (uint256 amountOut) {
    // Transfer the specified amount of stablecoin to this contract
    TransferHelper.safeTransferFrom(
      tokenIn,
      msg.sender,
      address(this),
      amountIn
    );

    // Approve the router to spend stablecoin
    TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

    // Swaps stablecoin for WETH
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: WETH,
        fee: POOL_FEE,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });

    // The amount of WETH received upon swap
    amountOut = swapRouter.exactInputSingle(params);
  }

  /// @notice TODO
  /// @dev First manually call Stablecoin contract "Approve" function.
  /// @param tokenIn: The address of the stablecoin contract
  /// @param decimalsOfInput: TODO
  function depositRPAndSendNFTLand(
    address tokenIn,
    uint256 amountIn,
    uint256 nftLandId,
    uint256 decimalsOfInput
  ) external returns (uint256 amountOut) {
    if (amountIn <= 0) revert EarthverseDeposit_InvalidDepositAmount();

    // Transfer NFTLand to the buyer
    address seller = IEarthverseMarketplace(earthverseMarketplace).buyNFTLand(
      msg.sender,
      nftLandId,
      amountIn,
      decimalsOfInput
    );

    // Min  ts the native NFTD token at 1 to 1 ratio and send to the seller
    INFTDollar(nftd).mint(seller, amountIn, decimalsOfInput);

    // Swaps stablecoin for WETH
    amountOut = swapExactInputSingle(amountIn, tokenIn);

    IWETH(WETH).withdraw(amountOut);

    // Queries the senders RETH balance prior to deposit
    uint256 rethBalance1 = IERC20(RETH).balanceOf(address(this));
    // Deposits the ETH and gets RETH back
    IRocketpool(ROCKET_POOL_DEPOSIT).deposit{value: amountOut}();
    // Queries the senders RETH balance after the deposit
    uint256 rethBalance2 = IERC20(RETH).balanceOf(address(this));
    if (rethBalance2 < rethBalance1) revert EarthverseDeposit_NoRETHWasMinted();
    uint256 rethMinted = rethBalance2 - rethBalance1;

    // Stores the amount of reth received by the user in a mapping
    balances[msg.sender] += rethMinted;

    emit StakedAndReceivedNFTLand(msg.sender, amountOut);
  }

  fallback() external payable {}

  receive() external payable {}
}
