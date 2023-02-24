//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/INFTDollar.sol";
import "./interfaces/IEarthverseMarketplace.sol";
import "./interfaces/IEarthverseDepositBSC.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract EarthverseDepositBSC {
  address public constant BNBX = 0x3ECB02c703C815e9cFFd8d9437B7A2F93638d7Cb;
  address public constant STADER_STAKE_MANAGER =
    0xDAdcae6bF110c0e70E5624bCdcCBe206f92A2Df9;

  address public immutable nftd;
  address public immutable earthverseMarketplace;
  IUniswapV2Router02 public immutable uniswapV2Router;

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
    uniswapV2Router = IUniswapV2Router02(
      0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    );
  }

  /// @notice swapExactTokensForETH swaps a fixed amount of stablecoin for a maximum possible amount of WBNB
  /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its stablecoin for this function to succeed.
  /// @param amountIn: The exact amount of stablecoin that will be swapped for WBNB.
  /// @param tokenIn: Stablecoin's address, which we will swap fro WBNB.
  function swapExactTokensForWBNB(uint256 amountIn, address tokenIn) private {
    // Transfer the specified amount of stablecoin to this contract.
    TransferHelper.safeTransferFrom(
      tokenIn,
      msg.sender,
      address(this),
      amountIn
    );

    // Approve the router to spend stablecoin.
    TransferHelper.safeApprove(tokenIn, address(uniswapV2Router), amountIn);

    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = uniswapV2Router.WETH();

    // Swaps stablecoin for WBNB
    uniswapV2Router.swapExactTokensForETH(
      amountIn,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  /// @notice TODO
  /// @dev First manually call Stablecoin contract "Approve" function.
  /// @param tokenIn: The address of the stablecoin contract
  function depositStaderAndSendNFTLand(
    address tokenIn,
    uint256 amountIn,
    uint256 nftLandId,
    uint256 decimalsOfInput
  ) external {
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

    // Swaps stablecoin for WBNB
    swapExactTokensForWBNB(amountIn, tokenIn);

    // Queries the senders BNBX balance prior to deposit
    uint256 bnbxBalance1 = IERC20(BNBX).balanceOf(address(this));
    uint256 balanceOfContract = address(this).balance;

    // Deposits the BNB and gets BNBX back
    IStaderStake(STADER_STAKE_MANAGER).deposit{value: balanceOfContract}();

    // Queries the senders BNBX balance after the deposit
    uint256 bnbxBalance2 = IERC20(BNBX).balanceOf(address(this));
    if (bnbxBalance2 < bnbxBalance1) revert EarthverseDeposit_NoBNBXWasMinted();
    uint256 bnbxMinted = bnbxBalance2 - bnbxBalance1;

    // Stores the amount of BNBX received by the user in a mapping
    balances[msg.sender] += bnbxMinted;

    emit StakedAndReceivedNFTLand(msg.sender, balanceOfContract);
  }

  fallback() external payable {}

  receive() external payable {}
}
