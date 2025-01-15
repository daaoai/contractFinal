// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Locker {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

contract LockerFactory {
    event LockerCreated(address indexed locker);

    function deployLocker(address owner) external returns (address) {
        Locker locker = new Locker(owner);
        emit LockerCreated(address(locker));
        return address(locker);
    }
}
