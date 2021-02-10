pragma solidity ^0.4.19;

import "./ERC20.sol";
import "./math.sol";

contract Spot is DSMath{

	address 	public QUOTE_TOKEN;

	function Spot(address quote_addr) public {
		QUOTE_TOKEN = quote_addr;
	}

	/*****************************
	 *
	 *	LENDER START
	 *
	 *****************************/

	address[] 	lenders;
	uint[]		lender_balances;

	function getLenders() public view returns (address[]) {
		return lenders;
	}
	function getLenderBalances() public view returns (uint[]) {
		return lender_balances;
	}

	function lenderDeposit(
		int 	idx, 
		address lender,
		uint	amount
	) public {
		// validate
		require(amount > 0);

		// update ledger
		if (idx == -1) {
			lenders.push(lender);
			lender_balances.push(amount);
		}
		else {
			lender_balances[uint(idx)] += amount;
		}

		// transfer funds
		ERC20(QUOTE_TOKEN).transferFrom(
			lender, 
			this,
			amount
		);
	}

	function lenderWithdraw(
		uint 	idx, 
		uint	amount,
		bytes32 agent_r, 
		bytes32 agent_s,
		uint8 	agent_v,
		bytes32 lender_r, 
		bytes32 lender_s,
		uint8 	lender_v,
		bytes32 sha
	) public {
		// validate
		require(amount > 0);
		require(lender_balances[idx] >= amount);
		
		// update ledger
		lender_balances[idx] -= amount;

		// transfer funds
		ERC20(QUOTE_TOKEN).transfer(
			lenders[idx], 
			amount
		);
	}

	/*
	 *
	 *	LENDER END
	 *
	 */

	/*****************************
	 *
	 *	SHORTSELLER START
	 *
	 *****************************/

	address[]	shortsellers;
	uint[]		shortseller_balances;

	function getShortsellers() public view returns (address[]) {
		return shortsellers;
	}
	function getShortsellerBalances() public view returns (uint[]) {
		return shortseller_balances;
	}

	function shortsellerDeposit(
		int 	idx
	) public payable {
		// validate
		require(msg.value > 0);

		// update ledger
		if (idx == -1) {
			shortsellers.push(msg.sender);
			shortseller_balances.push(msg.value);
		}
		else {
			shortseller_balances[uint(idx)] += msg.value;
		}
	}

	function shortsellerWithdraw(
		uint 	idx, 
		uint	amount,
		bytes32 agent_r, 
		bytes32 agent_s,
		uint8 	agent_v,
		bytes32 shortseller_r, 
		bytes32 shortseller_s,
		uint8 	shortseller_v,
		bytes32 sha
	) public {
		// validate
		require(amount > 0);
		require(shortseller_balances[idx] >= amount);

		// update ledger
		shortseller_balances[idx] -= amount;

		// transfer funds
		ERC20(QUOTE_TOKEN).transfer(
			shortsellers[idx], 
			amount
		);
	}

	/*
	 *
	 *	SHORTSELLER END
	 *
	 */


	/*****************************
	 *
	 *	AGREEMENT START
	 *
	 *****************************/

	address[]	agreements_shortseller;
	address[]	agreements_lender;
	uint[]		agreements_token;
	uint[]		agreements_amountBase;
	uint[]		agreements_rate;
	uint[]		agreements_timestamp;

	function getAgreementsShortseller() public view returns (address[]) {
		return agreements_shortseller;
	}
	function getAgreementsLender() public view returns (address[]) {
		return agreements_lender;
	}
	function getAgreementsToken() public view returns (uint[]) {
		return agreements_token;
	}
	function getAgreementsAmountBase() public view returns (uint[]) {
		return agreements_amountBase;
	}
	function getAgreementsRate() public view returns (uint[]) {
		return agreements_rate;
	}
	function getAgreementsTimestamp() public view returns (uint[]) {
		return agreements_timestamp;
	}

	function CreateAgreement(
		uint	shortseller_idx,
		uint	lender_idx,
		uint	token, 	
		uint	amountBase,
		uint 	rate,
		bytes32 agent_r, 
		bytes32 agent_s,
		uint8 	agent_v,
		bytes32 shortseller_r, 
		bytes32 shortseller_s,
		uint8 	shortseller_v,
		bytes32 sha
	) public {
		// validate 
		require(amountBase > 0);

		// update lender ledger
		lender_balances[lender_idx] -= amountBase / rate * 100;

		agreements_shortseller.push(shortsellers[shortseller_idx]);
		agreements_lender.push(lenders[lender_idx]);
		agreements_token.push(token);
		agreements_amountBase.push(amountBase);
		agreements_rate.push(rate);
		agreements_timestamp.push(now);
	}

	function DissolveAgreement(
		uint	agreement_idx,
		uint	shortseller_idx,
		uint	lender_idx,
		uint	due_lender,
		int		due_shortseller,
		bytes32 agent_r, 
		bytes32 agent_s,
		uint8 	agent_v,
		bytes32 r, 
		bytes32 s,
		uint8 	v,
		bytes32 sha
	) public {
		lender_balances[lender_idx] += due_lender;
		if (due_shortseller > 0) {
			shortseller_balances[shortseller_idx] += uint(due_shortseller);
		}
		else {
			shortseller_balances[shortseller_idx] -= uint(due_shortseller);
		}
		agreements_amountBase[agreement_idx] = 0;
	}

	/*
	 *
	 *	AGREEMENT END
	 *
	 */
}
