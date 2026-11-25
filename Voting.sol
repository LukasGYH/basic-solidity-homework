// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    // 1. mapping(键类型 => 值类型)：用候选人编号查票数。
    // 例如 voteCounts[7] 表示 7 号的票数。uint256 是无符号整数，从未写入的键读出来是 0。
    // 这和数组不同：7 是查找用的键，不是数组下标；不需要先插入 0 到 6。
    // private 不会生成公开 getter，所以对外查询统一走 getVotes；它不代表链上数据保密。
    mapping(uint256 => uint256) private voteCounts;

    // 2. 另一张表以投票者地址为键，记录本轮是否已经投过，未写入时默认 false。
    // 一地址一票，不是一自然人一票：同一个人可以控制多个地址。
    mapping(address => bool) private hasVoted;

    // mapping 擅长按键查值，却不能列出键。数组能用 length 和下标遍历，
    // 所以我们单独记下本轮哪些键被写过，留给 resetVotes 使用。
    uint256[] private votedCandidateIds;
    address[] private voterAddresses;

    // immutable 可以在部署时设定，部署后不能更改；public 会自动生成 owner() 查询函数。
    address public immutable owner;

    // constructor 只在部署时执行一次。这里的 msg.sender 是直接部署这个合约的地址。
    constructor() {
        owner = msg.sender;
    }

    // 3. vote 接收的是候选人编号；投票者取自 msg.sender，不让调用者自己填。
    // msg.sender 是直接调用者：钱包直调时是钱包地址，通过另一个合约调用时是那个合约的地址。
    // 本作业未规定候选人注册，所以任何 uint256 编号都可投；正式业务可另加候选人名单。
    function vote(uint256 candidateId) external {
        require(!hasVoted[msg.sender], "Already voted");
        // require 条件不成立会回滚。先检查，再写状态；同一地址也不能换个候选人再投。
        if (voteCounts[candidateId] == 0) {
            // 在本轮，票数只增不减，所以 0 表示这是该编号的第一票，只需登记一次。
            votedCandidateIds.push(candidateId);
        }

        voteCounts[candidateId] += 1;
        hasVoted[msg.sender] = true;
        voterAddresses.push(msg.sender);
    }

    // 4. view 表示只读状态，不改状态；returns 声明返回类型，return 返回具体值。
    // external 可从合约外调用。用钱包或客户端进行链下读取时，不必发送交易。
    function getVotes(uint256 candidateId) external view returns (uint256) {
        return voteCounts[candidateId];
    }

    // 5. 重置相当于开始下一轮：只清票数会让投过的人不能再投，两张表都要清理。
    function resetVotes() external {
        require(msg.sender == owner, "Only owner");

        // delete mapping[key] 不是让键「消失」，而是让这个键读回类型默认值。
        // 没有写过的候选人本来就是 0，不用遍历所有可能的编号。
        for (uint256 i = 0; i < votedCandidateIds.length; i++) {
            delete voteCounts[votedCandidateIds[i]];
        }
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            delete hasVoted[voterAddresses[i]];
        }

        // 和 Task.sol 的 delete data 对照：动态数组可以整体清空，mapping 不行。
        // 要先用清单找到键，再清空清单；反过来会丢失要清理的键。
        delete votedCandidateIds;
        delete voterAddresses;

        // 延伸：清理成本随名单增长，超过区块 Gas 上限时重置可能无法完成。
        // 另一种设计是按轮次存数据：新一轮使用新的键空间，旧轮次数据仍在链上。
    }
}
