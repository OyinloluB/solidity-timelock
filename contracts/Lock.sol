// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";

/**
    @dev
    Purpose is to prevent transaction from taking place until a time frame has elapsed,
    in that time, user should be able to cancel the transaction.
*/
contract Timelock {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    error TxnAlreadyQueued(bytes32 txnId);
    error TxnDoesNotExistOnQueue(bytes32 txnId);
    error TxnStillLocked(uint blockTimestamp, uint timestamp);
    error TxnExpired(uint blockTimestamp, uint timestamp);
    error TxnFailed();

    uint256 public constant DURATION = 1000;
    uint256 public constant GRACE_PERIOD = 10000;

    mapping(bytes32 => bool) public txnQueue;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @dev This function adds a transaction to a queue
    function addToTxnQueue(
        uint _timestamp,
        address _contractAddress,
        string calldata _function,
        uint _value,
        bytes calldata _data
    ) external onlyOwner returns (bytes32 txnId) {
        // get txnId
        bytes32 txnId = keccak256(abi.encode(_timestamp, _contractAddress, _function, _value, _data));
        // check if txn has already been queued
        if (txnQueue[txnId]) {
            revert TxnAlreadyQueued(txnId);
        }

        // add txn to queue
        txnQueue[txnId] = true;
    }

    /// @dev This function removes a transaction from a queue / cancels txn
    function removeFromTxnQueue(bytes32 _txnId, uint _timestamp) external onlyOwner {
        if (!txnQueue[_txnId]) {
            revert TxnDoesNotExistOnQueue(_txnId);
        }

        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TxnExpired(block.timestamp, _timestamp);
        }

        txnQueue[_txnId] = false;
    }

    /// @dev This function executes the transaction
    function executeTxn(
        uint _timestamp,
        address _contractAddress,
        string calldata _function, 
        uint _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        // get txnId
        bytes32 txnId = keccak256(abi.encode(_timestamp, _contractAddress, _function, _value, _data));
        //check if txn has been queued
        if (txnQueue[txnId]) {
            revert TxnDoesNotExistOnQueue(txnId);
        }

        // check if the txn is still locked
        if (block.timestamp < _timestamp) {
            revert TxnStillLocked(block.timestamp, _timestamp);
        }

        // check if the txn has expired
        if (block.timestamp > _timestamp + DURATION + GRACE_PERIOD) {
            revert TxnExpired(block.timestamp, _timestamp + DURATION + GRACE_PERIOD);
        }

        // remove txn from queue
        txnQueue[txnId] = false;

        // prepare data to be passed into excecuted contract
        bytes memory data;

        // check if _function is empty and abi encode data if it is not
        if (bytes(_function).length > 0) {
            data = abi.encodePacked(bytes4(keccak256(bytes(_function))), _data);
        } else {
            data = _data;
        }

        (bool ok, bytes memory res) = _contractAddress.call{value: _value}(data);
        if (!ok) {
            revert TxnFailed();
        }

        return res;
    }

    receive() external payable {}
}

///@dev Will be used to test contract
contract TestTimeLock {
    address public timelock;

    constructor(address _timelock) {
        timelock = _timelock;
    }

    function test() external view {
        require(msg.sender == timelock);
    }

    function getTimestamp() external view returns (uint) {
        return block.timestamp + 100;
    }
}