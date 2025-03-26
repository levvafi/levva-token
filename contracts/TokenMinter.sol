//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Mintable {
  function mint(address to, uint256 amount) external;
}

/// @title Token minter contract
/// @author EqLab
/// @notice Contract that allows to mint tokens according to the specified schedule
contract TokenMinter is Ownable2Step {
  /* Type declarations */
  struct MintConfig {
    /// @dev Before the start time minting is not available
    uint64 startTime;
    /// @dev Period length in seconds
    uint64 periodLength;
    /// @dev Period shift in seconds for making beginning of period more flexible
    uint64 periodShift;
    /// @dev Maximum count of mints
    uint64 maxCountOfMints;
    /// @dev Amount of tokens to mint for each period
    uint256 mintAmount;
  }

  struct Allocation {
    /// @dev Recipient of the minted tokens
    address recipient;
    ///@dev Share of the minted tokens
    uint96 share;
  }

  /* State variables */
  /// @dev Represents 100%
  uint96 private constant ONE = 10 ** 18;

  /// @dev Address of a token to mint
  address private immutable i_token;

  /// @dev Operators who can perform minting
  mapping(address => bool) private s_operators;

  /// @dev Minting configuration
  MintConfig private s_mintConfig;

  /// @dev Time of the last mint in seconds
  uint256 private s_lastMintTime;

  /// @dev Counter of the mint operations
  uint32 private s_mintCounter;

  /// @dev List of allocations
  Allocation[] private s_allocations;

  /* Events */
  event OperatorAdded(address indexed operator);
  event OperatorRemoved(address indexed operator);
  event Mint(uint256 amount, uint256 mintCounter);

  /* Errors */
  error AdminContract__InvalidAddress();
  error AdminContract__Unauthorized();
  error AdminContract__WrongAllocationsShare();
  error AdminContract__MintNotAvailable();
  error AdminContract__InvalidMintConfig();

  /* Modifiers */
  modifier onlyOperator() {
    ensureOperator(msg.sender);
    _;
  }

  /// Contract constructor
  /// @param token IERC20 token address, should be mintable, should transfer ownership or mint rights to this contract
  /// @param initialOwner Initial owner of the contract
  /// @param mintConfig Initial minting configuration
  /// @param allocations Initial list of allocations
  constructor(
    address token,
    address initialOwner,
    MintConfig memory mintConfig,
    Allocation[] memory allocations
  ) Ownable(initialOwner) {
    if (address(0) == token) {
      revert AdminContract__InvalidAddress();
    }

    i_token = token;
    _updateMintConfig(mintConfig);
    _updateAllocations(allocations);
  }

  /// @notice Mint tokens according to the schedule
  /// @dev Available only for operators
  function mint() external onlyOperator {
    MintConfig memory mintConfig = s_mintConfig;
    if (!_canMint(mintConfig)) revert AdminContract__MintNotAvailable();

    uint256 restAmount = mintConfig.mintAmount;
    uint256 length = s_allocations.length;

    emit Mint(mintConfig.mintAmount, s_mintCounter);

    s_lastMintTime = block.timestamp;
    s_mintCounter += 1;

    for (uint256 i = 0; i < length; ) {
      Allocation memory allocation = s_allocations[i];
      uint256 mintAmount = (i == length - 1) ? restAmount : (mintConfig.mintAmount * allocation.share) / ONE;

      IERC20Mintable(i_token).mint(allocation.recipient, mintAmount);
      restAmount -= mintAmount;

      unchecked {
        ++i;
      }
    }
  }

  /// @dev Transfer ownership of the token to another address
  /// @param newTokenOwner new token owner address
  function transferTokenOwnership(address newTokenOwner) external onlyOwner {
    if (newTokenOwner == address(0)) {
      revert AdminContract__InvalidAddress();
    }

    Ownable(i_token).transferOwnership(newTokenOwner);
  }

  /// Adds new operator
  /// @dev Only owner can add operator
  /// @param operator Address of the operator
  /// @param add True to add operator, false to remove
  function addOperator(address operator, bool add) external onlyOwner {
    if (operator == address(0)) {
      revert AdminContract__InvalidAddress();
    }

    s_operators[operator] = add;
  }

  /// Updates allocations
  /// @dev Only owner can update allocations
  /// @param allocations List of allocations
  function updateAllocations(Allocation[] memory allocations) external onlyOwner {
    _updateAllocations(allocations);
  }

  /// Updates minting configuration
  /// @dev Only owner can update minting configuration
  /// @param mintConfig New minting configuration
  function updateMintConfig(MintConfig memory mintConfig) external onlyOwner {
    _updateMintConfig(mintConfig);
  }

  /// Checks if minting is available
  function canMint() external view returns (bool) {
    return _canMint(s_mintConfig);
  }

  /// Ensures that the address is operator
  /// @param _operator Address of the operator
  function ensureOperator(address _operator) private view {
    if (!s_operators[_operator]) revert AdminContract__Unauthorized();
  }

  function getToken() public view returns (address) {
    return i_token;
  }

  function getMintConfig() public view returns (MintConfig memory) {
    return s_mintConfig;
  }

  function getAllocations() public view returns (Allocation[] memory) {
    return s_allocations;
  }

  function getLastMintTime() public view returns (uint256) {
    return s_lastMintTime;
  }

  function getMintCount() public view returns (uint32) {
    return s_mintCounter;
  }

  function _updateMintConfig(MintConfig memory mintConfig) private {
    if (mintConfig.startTime == 0) revert AdminContract__InvalidMintConfig();
    if (mintConfig.periodLength == 0) revert AdminContract__InvalidMintConfig();

    s_mintConfig = mintConfig;
  }

  function _updateAllocations(Allocation[] memory allocations) private {
    uint256 totalShare = 0;
    for (uint256 i = 0; i < allocations.length; ) {
      if (allocations[i].recipient == address(0)) revert AdminContract__InvalidAddress();

      totalShare += allocations[i].share;

      unchecked {
        ++i;
      }
    }

    if (totalShare != ONE) revert AdminContract__WrongAllocationsShare();

    s_allocations = allocations;
  }

  function _canMint(MintConfig memory mintConfig) private view returns (bool) {
    if (s_mintCounter >= mintConfig.maxCountOfMints) return false;

    uint256 curPeriodBegin = (block.timestamp / mintConfig.periodLength) *
      mintConfig.periodLength +
      mintConfig.periodShift;
    uint256 curPeriodEnd = curPeriodBegin + mintConfig.periodLength;

    if (block.timestamp < mintConfig.startTime) return false;

    uint256 lastMintTime = s_lastMintTime;
    if (lastMintTime >= curPeriodBegin && lastMintTime < curPeriodEnd) return false;

    return true;
  }
}
