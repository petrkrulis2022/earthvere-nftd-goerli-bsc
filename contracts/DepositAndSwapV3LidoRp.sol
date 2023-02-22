//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/INFTDollar.sol";
import "./interfaces/INFTLand.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRocketpool {
  function deposit() external payable;
}

interface ILido {
  function submit(address _referral) external payable returns (uint256);

  function balanceOf(address account) external view returns (uint256);
}

interface IWETH {
  function approve(address sender, uint256 amount) external;

  function withdraw(uint256 amount) external;
}

error DepositAndSwapV3LidoRp_ZeroAddress();

/// @notice TODO
contract DepositAndSwapV3LidoRP {
  address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
  address public constant LIDO = 0x2DD6530F136D2B56330792D46aF959D9EA62E276;
  address public constant RETH = 0x178E141a0E3b34152f73Ff610437A7bf9B83267A;
  address public constant ROCKET_POOL_DEPOSIT =
    0x2cac916b2A963Bf162f076C0a8a4a8200BCFBfb4;

  uint24 public constant POOL_FEE = 3000;

  address public immutable nftd;
  address public immutable nftl;
  ISwapRouter public immutable swapRouter;

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256))
    public totalSwappedStablecoins;
  mapping(address => uint256) public depositedRethByUser;
  mapping(address => uint256) public depositedLidoByUser;

  event DepositReceived(
    address indexed sender,
    address indexed poolAddress,
    uint256 indexed amount
  );

  constructor() {
    // constructor(address _nftd, address _nftl) {
    // if (_nftd == address(0) || _nftl == address(0))
    //   revert DepositAndSwapV3LidoRp_ZeroAddress();

    nftd = address(0x0);
    nftl = address(0x0);
    swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  }

  /// @notice swapExactInputSingle swaps a fixed amount of stablecoin for a maximum possible amount of WETH
  /// using the stablecoin/WETH 0.3% pool by calling `exactInputSingle` in the swap router.
  /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its stablecoin for this function to succeed.
  /// @param amountIn The exact amount of stablecoin that will be swapped for WETH.
  /// @return amountOut The amount of WETH received.
  function swapExactInputSingle(
    uint256 amountIn,
    address tokenIn
  ) private returns (uint256 amountOut) {
    // Transfer the specified amount of stablecoin to this contract.
    TransferHelper.safeTransferFrom(
      tokenIn,
      msg.sender,
      address(this),
      amountIn
    );

    // Approve the router to spend stablecoin.
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
  /// @param amountIn: TODO
  /// @param tokenIn: The address of the stablecoin contract
  /// @param decimalsOfInput: TODO
  /// @param nftLandTokenURI: TODO
  function swapRP(
    uint256 amountIn,
    address tokenIn,
    uint256 decimalsOfInput,
    string memory nftLandTokenURI
  ) external returns (uint256 amountOut) {
    amountOut = swapExactInputSingle(amountIn, tokenIn);
    require(amountOut > 0, "Invalid deposit amount");

    // Mints the native NFTD token at 1 to 1 ratio
    //INFTDollar(nftd).mint(msg.sender, amountIn, decimalsOfInput);
    // Mints the NFTLand plot
    //INFTLand(nftl).safeMintNFT(msg.sender, nftLandTokenURI);

    // Stores how much ETH the user has swapped so far
    balances[msg.sender] = balances[msg.sender] + amountOut;

    // Unwraps the ETH as RocketPool accepts only plain ETH
    IWETH(WETH).withdraw(amountOut);

    // Queries the senders RETH balance prior to deposit
    uint256 rethBalance1 = IERC20(RETH).balanceOf(address(this));
    // Deposits the ETH and gets RETH back
    IRocketpool(ROCKET_POOL_DEPOSIT).deposit{value: amountOut}();
    // Queries the senders RETH balance after the deposit
    uint256 rethBalance2 = IERC20(RETH).balanceOf(address(this));
    require(rethBalance2 > rethBalance1, "No rETH was minted");
    uint256 rethMinted = rethBalance2 - rethBalance1;

    // Stores the amount of reth received by the user in a mapping
    depositedRethByUser[msg.sender] =
      depositedRethByUser[msg.sender] +
      rethMinted;
    totalSwappedStablecoins[address(this)][tokenIn] =
      totalSwappedStablecoins[address(this)][tokenIn] +
      amountIn;

    emit DepositReceived(msg.sender, ROCKET_POOL_DEPOSIT, amountOut);
  }

  /// @notice TODO
  /// @param amountIn: TODO
  /// @param tokenIn: TODO
  /// @param decimalsOfInput: TODO
  /// @param nftLandTokenURI: TODO
  function swapLI(
    uint256 amountIn,
    address tokenIn,
    uint256 decimalsOfInput,
    string memory nftLandTokenURI
  ) external returns (uint256 amountOut) {
    amountOut = swapExactInputSingle(amountIn, tokenIn);
    require(amountOut > 0, "Invalid deposit amount");

    // Mints the native NFTD token at 1 to 1 ratio
    INFTDollar(nftd).mint(msg.sender, amountIn, decimalsOfInput);
    // Mints the NFTLand plot
    //INFTLand(nftl).safeMintNFT( nftLandTokenURI);

    // the amount of weth received upon swap
    balances[msg.sender] = balances[msg.sender] + amountOut; //stores how much ETH the user has swapped so far
    IWETH(WETH).withdraw(amountOut); //unwraps the ETH as RocketPool accepts only plain ETH
    uint256 lidoBalance1 = ILido(LIDO).balanceOf(address(this)); // queries the msg.senders StEth balance prior to deposit
    ILido(LIDO).submit{value: amountOut}(msg.sender); //deposits to Lido
    uint256 lidoBalance2 = ILido(LIDO).balanceOf(address(this)); // queries the msg.senders StEth balance after the deposit
    uint256 depositedStEth = lidoBalance2 - lidoBalance1;

    depositedLidoByUser[msg.sender] += depositedStEth; //stores the amount of stEth received by the user in a mapping.
    totalSwappedStablecoins[address(this)][tokenIn] =
      totalSwappedStablecoins[address(this)][tokenIn] +
      amountIn;

    emit DepositReceived(msg.sender, LIDO, amountOut);
  }

  fallback() external payable {}

  receive() external payable {}
}
