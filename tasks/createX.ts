// https://createx.rocks/deployments
export const CREATE_X_ADDRESS = '0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed';

// https://createx.rocks/abi#ethers-js
export const CREATE_X_ABI = [
  'error FailedContractCreation(address)',
  'error FailedContractInitialisation(address,bytes)',
  'error FailedEtherTransfer(address,bytes)',
  'error InvalidNonceValue(address)',
  'error InvalidSalt(address)',
  'event ContractCreation(address indexed,bytes32 indexed)',
  'event ContractCreation(address indexed)',
  'event Create3ProxyContractCreation(address indexed,bytes32 indexed)',
  'function computeCreate2Address(bytes32,bytes32) view returns (address)',
  'function computeCreate2Address(bytes32,bytes32,address) pure returns (address)',
  'function computeCreate3Address(bytes32,address) pure returns (address)',
  'function computeCreate3Address(bytes32) view returns (address)',
  'function computeCreateAddress(uint256) view returns (address)',
  'function computeCreateAddress(address,uint256) view returns (address)',
  'function deployCreate(bytes) payable returns (address)',
  'function deployCreate2(bytes32,bytes) payable returns (address)',
  'function deployCreate2(bytes) payable returns (address)',
  'function deployCreate2AndInit(bytes32,bytes,bytes,tuple(uint256,uint256),address) payable returns (address)',
  'function deployCreate2AndInit(bytes,bytes,tuple(uint256,uint256)) payable returns (address)',
  'function deployCreate2AndInit(bytes,bytes,tuple(uint256,uint256),address) payable returns (address)',
  'function deployCreate2AndInit(bytes32,bytes,bytes,tuple(uint256,uint256)) payable returns (address)',
  'function deployCreate2Clone(bytes32,address,bytes) payable returns (address)',
  'function deployCreate2Clone(address,bytes) payable returns (address)',
  'function deployCreate3(bytes) payable returns (address)',
  'function deployCreate3(bytes32,bytes) payable returns (address)',
  'function deployCreate3AndInit(bytes32,bytes,bytes,tuple(uint256,uint256)) payable returns (address)',
  'function deployCreate3AndInit(bytes,bytes,tuple(uint256,uint256)) payable returns (address)',
  'function deployCreate3AndInit(bytes32,bytes,bytes,tuple(uint256,uint256),address) payable returns (address)',
  'function deployCreate3AndInit(bytes,bytes,tuple(uint256,uint256),address) payable returns (address)',
  'function deployCreateAndInit(bytes,bytes,tuple(uint256,uint256)) payable returns (address)',
  'function deployCreateAndInit(bytes,bytes,tuple(uint256,uint256),address) payable returns (address)',
  'function deployCreateClone(address,bytes) payable returns (address)',
];