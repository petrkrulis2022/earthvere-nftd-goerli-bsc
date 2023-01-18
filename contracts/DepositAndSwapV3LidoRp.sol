//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

//Goerli
/// the contract still needs to have the burn method of the Reth contract invoked ( at address 0x178e141a0e3b34152f73ff610437a7bf9b83267a ) so that it is able to unstake the reth and convert it back to eth
// also need another mapping to store the amount of reth received from every swap of every msg.sender ( sincre reth/eth ratio is not 1:1.  ====DONE
//this contract should also be approved to spend the tokens. It mmust be approved manually by the msg.sender by invoking the approve function in the USDT contract and using this contract's address as input

interface INFTDollar {
  function mint(address to, uint256 amount, uint256 decimalsOfInput) external;
}

interface IUniswap {
  function swapExactInputSingle(
    uint256 amountIn
  ) external returns (uint256 amountOut);
}

interface IUSDT {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
}

interface IRocketpool {
  function deposit() external payable;
}

interface ILido {
  function submit(address _referral) external payable returns (uint256);

  function balanceOf(address account) external view returns (uint256);
}

interface Iweth {
  function approve(address _address, uint amount) external;

  function withdraw(uint wad) external;
}

interface INFTLandToken {
  function mint(address _address) external payable returns (uint256);
}

interface RETH {
  function balanceOf(address account) external view returns (uint256);
}

contract DepositAndSwapV3LidoRP is VRFConsumerBaseV2, ConfirmedOwner {
  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256))
    public totalSwappedStablecoins;
  mapping(address => uint256) public depositedRethByUser;
  mapping(address => uint256) public depositedLidoByUser;

  address constant RocketpoolAddress =
    0x2cac916b2A963Bf162f076C0a8a4a8200BCFBfb4;
  address constant testETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
  address constant NFTD = 0x0C9653f527aa980cacb23E834D79fc5F1A6f2B28;
  address constant NFTLand = 0x9a565Ac0E639A2D207925Be58BaBf5703370891b;
  address constant RethTokenAddress =
    0x178E141a0E3b34152f73Ff610437A7bf9B83267A;
  address constant LidoContractAddress =
    0x2DD6530F136D2B56330792D46aF959D9EA62E276;
  ISwapRouter public immutable swapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  event Deposited(
    address indexed from,
    address indexed selectedPool,
    uint256 indexed amount
  );
  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint256 amountOutMin = 0; // best to be kept at 0, otherwise swap may not happen
  uint24 constant poolFee = 3000;

  // 1. approving the router
  // 2. transfer stablecoin to this contract
  // 3. Mints the native NFTD token at 1 to 1 ratio
  // 4. Swaps stablecoin for weth
  // 5. unrwaps the weth for eth
  // 6. deposits the eth and gets Reth back
  // 7. Mints NFTLand plot

  /// @notice TODO
  /// @param amountIn: TODO
  /// @param tokenIn: TODO
  /// @param decimalsOfInput: TODO
  function swapRP(
    uint256 amountIn,
    address tokenIn,
    uint256 decimalsOfInput
  ) external returns (uint256) {
    // first manyally approve this contract to spend the selected stablecoi nform the stablecoins contract !
    TransferHelper.safeTransferFrom(
      tokenIn,
      msg.sender,
      address(this),
      amountIn
    ); // transfers the selected stablecoin to this contract
    TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn); // approves the router to spend the USDT on behalf of the msg.sender
    INFTDollar(NFTD).mint(msg.sender, amountIn, decimalsOfInput); //mints the native NFTD token
    INFTLandToken(NFTLand).mint(msg.sender); // Mints the NFTLand plot

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: testETH,
        fee: poolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });
    //calls the function from the Uniswap interface
    uint256 amount = swapRouter.exactInputSingle(params);
    // the amount of weth received upon swap
    balances[msg.sender] = balances[msg.sender] + amount; //stores how much eth the user has swapped so far
    Iweth(testETH).withdraw(amount); //unwraps the eth as RocketPool accepts only plain eth
    uint256 rethBalance1 = RETH(RethTokenAddress).balanceOf(address(this)); // queries the msg.senders RETH balance prior to deposit
    IRocketpool(RocketpoolAddress).deposit{value: amount}(); //deposits to rocketpool
    uint256 rethBalance2 = RETH(RethTokenAddress).balanceOf(address(this)); // queries the msg.senders RETH balance after the deposit
    uint256 depositedReth = rethBalance2 - rethBalance1;
    depositedRethByUser[msg.sender] += depositedReth; //stores the amount of reth received by the user in a mapping.
    totalSwappedStablecoins[address(this)][tokenIn] += amountIn; // adds the swapped amount of the selected stablecoin to the _TotalSwappdStablecoins mapping, which will be used for getter functions in the frontend.
    emit Deposited(msg.sender, RocketpoolAddress, amount);

    return amount;
  }

  /// @notice TODO
  /// @param amountIn: TODO
  /// @param tokenIn: TODO
  /// @param decimalsOfInput: TODO
  function swapLI(
    uint256 amountIn,
    address tokenIn,
    uint256 decimalsOfInput
  ) external returns (uint256) {
    // first manyally approve this contract to spend the selected stablecoi nform the stablecoins contract !
    TransferHelper.safeTransferFrom(
      tokenIn,
      msg.sender,
      address(this),
      amountIn
    ); // transfers the selected stablecoin to this contract
    TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn); // approves the router to spend the USDT on behalf of the msg.sender
    INFTDollar(NFTD).mint(msg.sender, amountIn, decimalsOfInput); //mints the native NFTD token
    INFTLandToken(NFTLand).mint(msg.sender); // Mints the NFTLand plot

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: testETH,
        fee: poolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });
    //calls the function from the Uniswap interface
    uint256 amount = swapRouter.exactInputSingle(params);
    // the amount of weth received upon swap
    balances[msg.sender] = balances[msg.sender] + amount; //stores how much eth the user has swapped so far
    Iweth(testETH).withdraw(amount); //unwraps the eth as RocketPool accepts only plain eth
    uint256 lidoBalance1 = ILido(LidoContractAddress).balanceOf(address(this)); // queries the msg.senders StEth balance prior to deposit
    ILido(LidoContractAddress).submit{value: amount}(msg.sender); //deposits to Lido
    uint256 lidoBalance2 = ILido(LidoContractAddress).balanceOf(address(this)); // queries the msg.senders StEth balance after the deposit
    uint256 depositedStEth = lidoBalance2 - lidoBalance1;
    depositedLidoByUser[msg.sender] += depositedStEth; //stores the amount of stEth received by the user in a mapping.
    totalSwappedStablecoins[address(this)][tokenIn] += amountIn; // adds the swapped amount of the selected stablecoin to the _TotalSwappdStablecoins mapping, which will be used for getter functions in the frontend.
    emit Deposited(msg.sender, LidoContractAddress, amount);

    return amount;
  }

  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256[] randomWords);

  struct RequestStatus {
    bool fulfilled; // Whether the request has been successfully fulfilled
    bool exists; // Whether a requestId exists
    uint256[] randomWords;
  }
  mapping(uint256 => RequestStatus)
    public s_requests; /* requestId --> requestStatus */
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Past requests Id.
  uint256[] public requestIds;
  uint256 public lastRequestId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
  bytes32 keyHash =
    0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords = 2;

  /**
   * HARDCODED FOR GOERLI
   * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
   */
  constructor(
    uint64 subscriptionId
  )
    VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
    ConfirmedOwner(msg.sender)
  {
    COORDINATOR = VRFCoordinatorV2Interface(
      0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
    );
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  /// @notice TODO
  function requestRandomWords() external returns (uint256 requestId) {
    // Will revert if subscription is not set and funded.
    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    s_requests[requestId] = RequestStatus({
      randomWords: new uint256[](0),
      exists: true,
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    return requestId;
  }

  /// @notice TODO
  /// @param _requestId: TODO
  /// @param _randomWords: TODO
  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  ) internal override {
    require(s_requests[_requestId].exists, "request not found");
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomWords = _randomWords;
    emit RequestFulfilled(_requestId, _randomWords);
  }

  /// @notice TODO
  /// @param _requestId: TODO
  function getRequestStatus(
    uint256 _requestId
  ) external view returns (bool fulfilled, uint256[] memory randomWords) {
    require(s_requests[_requestId].exists, "request not found");
    RequestStatus memory request = s_requests[_requestId];
    return (request.fulfilled, request.randomWords);
  }

  fallback() external payable {}

  receive() external payable {}
}
