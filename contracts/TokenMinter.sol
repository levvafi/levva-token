//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable, Ownable2Step} from '@openzeppelin/contracts/access/Ownable2Step.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Mintable {
  function mint(address to, uint256 amount) external;
}

/// @title Token minter contract
/// @author EqLab
/// @notice Contract that allows to mint tokens according to a specified schedule.
contract TokenMinter is Ownable2Step {
  /* Type declarations */
  struct MintConfig {
    /// @dev Before the start time minting is not available
    uint64 startTime;
    /// @dev Period length in seconds. Should be greater than zero, should be greater than periodShift
    uint64 periodLength;
    /// @dev Period shift in seconds for making beginning of period more flexible. Should be less than periodLength
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
  uint128 private s_lastMintTime;

  /// @dev Counter of the mint operations
  uint32 private s_mintCount;

  /// @dev List of allocations
  Allocation[] private s_allocations;

  /* Events */
  event OperatorChanged(address indexed operator, bool added);
  event Mint(uint256 amount, uint256 mintCount);

  /* Errors */
  error TokenMinter__InvalidAddress();
  error TokenMinter__Unauthorized();
  error TokenMinter__InvalidShares();
  error TokenMinter__MintNotAvailable();
  error TokenMinter__InvalidMintConfig();

  /* Modifiers */
  modifier onlyOperator() {
    _ensureOperator(msg.sender);
    _;
  }

  /// Contract constructor
  /// @param token IERC20 token address, should be mintable, should transfer ownership or mint rights to this contract
  /// @param initialOwner Initial owner of the contract
  /// @param mintConfig Initial minting configuration
  /// @param allocations Initial list of allocations
  /// @param operators Initial list of operators
  constructor(
    address token,
    address initialOwner,
    MintConfig memory mintConfig,
    Allocation[] memory allocations,
    address[] memory operators
  ) Ownable(initialOwner) {
    if (token == address(0)) {
      revert TokenMinter__InvalidAddress();
    }

    i_token = token;
    _updateMintConfig(mintConfig);
    _updateAllocations(allocations);

    uint256 length = operators.length;
    for (uint256 i; i < length; i++) {
      _addOperator(operators[i], true);

      unchecked {
        ++i;
      }
    }
  }

  /// @notice Mint tokens according to the schedule
  /// @dev Available only for operators
  function mint() external onlyOperator {
    MintConfig memory mintConfig = s_mintConfig;
    if (!_canMint(mintConfig)) {
      revert TokenMinter__MintNotAvailable();
    }

    s_lastMintTime = uint128(block.timestamp); // safe
    uint32 newMintCount = s_mintCount + 1;
    s_mintCount = newMintCount;

    emit Mint(mintConfig.mintAmount, newMintCount);

    IERC20Mintable token = IERC20Mintable(i_token);
    uint256 restAmount = mintConfig.mintAmount;
    uint256 length = s_allocations.length;

    for (uint256 i = 0; i < length; ) {
      Allocation memory allocation = s_allocations[i];
      uint256 mintAmount = (i == length - 1) ? restAmount : (mintConfig.mintAmount * allocation.share) / ONE;

      token.mint(allocation.recipient, mintAmount);
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
      revert TokenMinter__InvalidAddress();
    }

    Ownable(i_token).transferOwnership(newTokenOwner);
  }

  /// Adds new operator
  /// @dev Only owner can add operator
  /// @param operator Address of the operator
  /// @param add True to add operator, false to remove
  function addOperator(address operator, bool add) external onlyOwner {
    _addOperator(operator, add);
  }

  /// Updates allocations
  /// @dev Only owner can update allocations
  /// @param allocations List of allocations
  function updateAllocations(Allocation[] calldata allocations) external onlyOwner {
    _updateAllocations(allocations);
  }

  /// Updates minting configuration
  /// @dev Only owner can update minting configuration
  /// @param mintConfig New minting configuration
  function updateMintConfig(MintConfig calldata mintConfig) external onlyOwner {
    _updateMintConfig(mintConfig);
  }

  /// Checks if minting is available
  function canMint() external view returns (bool) {
    return _canMint(s_mintConfig);
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
    return s_mintCount;
  }

  function isOperator(address operator) public view returns (bool) {
    return s_operators[operator];
  }

  function _addOperator(address operator, bool add) private {
    if (operator == address(0)) {
      revert TokenMinter__InvalidAddress();
    }

    s_operators[operator] = add;
    emit OperatorChanged(operator, add);
  }

  function _updateMintConfig(MintConfig memory mintConfig) private {
    if (mintConfig.periodShift >= mintConfig.periodLength) revert TokenMinter__InvalidMintConfig();

    s_mintConfig = mintConfig;
  }

  function _updateAllocations(Allocation[] memory allocations) private {
    uint256 totalShare = 0;
    for (uint256 i; i < allocations.length; ) {
      if (allocations[i].recipient == address(0)) revert TokenMinter__InvalidAddress();

      totalShare += allocations[i].share;

      unchecked {
        ++i;
      }
    }

    if (totalShare != ONE) revert TokenMinter__InvalidShares();

    s_allocations = allocations;
  }

  function _ensureOperator(address _operator) private view {
    if (!s_operators[_operator]) revert TokenMinter__Unauthorized();
  }

  function _canMint(MintConfig memory mintConfig) private view returns (bool) {
    if (s_mintCount >= mintConfig.maxCountOfMints) return false;

    uint256 curPeriodBegin = block.timestamp - (block.timestamp % mintConfig.periodLength) + mintConfig.periodShift;

    if (block.timestamp < mintConfig.startTime) return false;

    if (s_lastMintTime >= curPeriodBegin) return false;

    return true;
  }
}
