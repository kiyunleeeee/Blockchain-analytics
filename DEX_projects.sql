-- Decentralized exchange (DEX)-related SQL-based projects for graduate-level blockchain analytics course
-- Created by kiyunlee on 06/10/2022


-- Description
-- 1. These are 5 DEX-related projects that I (kiyunlee) built on June, 2022.
-- 2. In terms of timeline of the course, students need to complete at the 7th week of the course.
-- 3. Students should select one project, build and submit an interactive SQL dashboard on Flipside Crypto or Dune.
-- 4. Due to reuse of the projects with modifications over the course, here I show simpler versions of questionnaires and solutions.





-- Project 1
-- Some stablecoins are designed to be pegged to fiat money. Investigate how well the following stablecoins maintain their peg to $1.
-- Analyze price deviations of five popular stablecoins, USDT, USDC, BUSD, DAI, and UST.
-- a. Find daily prices of USDT, USDC, BUSD, and DAI. Do they seem to be pegged to $1?
   -- Create a visualization showing the daily prices of each token over date.
-- b. Now, add daily prices of UST. Does it seem to be pegged to $1?
   -- Create a visualization showing the daily prices of each token over date.
-- c. Find price deviations of each token. Show a table with tokens, average prices, and standard deviations (note stddev() will be useful).


select left(hour, 10) as date, symbol, avg(price) as daily_price
from ethereum.core.fact_hourly_token_prices
where symbol in ('USDT', 'USDC', 'BUSD', 'DAI')
group by date, symbol
order by date

select left(hour, 10) as date, symbol, avg(price) as daily_price
from ethereum.core.fact_hourly_token_prices
where symbol in ('USDT', 'USDC', 'BUSD', 'DAI', 'UST')
group by date, symbol
order by date

with info as (
select left(hour, 10) as date, symbol, avg(price) as daily_price
from ethereum.core.fact_hourly_token_prices
where symbol in ('USDT', 'USDC', 'BUSD', 'DAI', 'UST')
group by date, symbol
order by date
)
select symbol, avg(daily_price) as ave_price, stddev(daily_price) as std_price
from info
group by symbol






-- Project 2
-- Wrapped tokens are used in swap activities. Analyze swap activities of one of the wrapped tokens, WETH on DEXs.
-- a. Analyze swap amounts where WETH is "swap from" and "swap to" separately. 
   -- Show a table with time stamps, DEX platforms, symbols of tokens in and out, token IDs in and out, and amount in USD in and out. 
   -- Token ID for WETH can be found on Etherscan.
-- b. Do users want to use WETH to swap something or want to get WETH? 
   -- Create two visualizations showing daily numbers of transactions and daily swap amounts separated by in and out. 
   -- How do the transaction numbers and swap amounts differ from in and out?
-- c. Now, pick the swap activity of either in or out. 
   -- Create two visualizations showing daily numbers of transactions separated by platforms, and daily swap amounts by platforms. 
   -- Explain what you observe from these two.


select date(BLOCK_TIMESTAMP) as date, platform, amount_in_usd, amount_out_usd, symbol_in, symbol_out, token_in, token_out, tx_hash
from ethereum.core.ez_dex_swaps
where token_in = lower('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2') -- token ID for WETH
	or token_out = lower('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
	and (amount_in_usd > 0 and amount_out_usd > 0)

  
with info as (
	select date(BLOCK_TIMESTAMP) as date, platform, amount_in_usd, amount_out_usd, symbol_in, symbol_out, token_in, token_out, tx_hash
	from ethereum.core.ez_dex_swaps
	where token_in = lower('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
		or token_out = lower('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
		and (amount_in_usd > 0 and amount_out_usd > 0)
)
select date,
	case when symbol_in = 'WETH' then 'IN'
  		when symbol_out = 'WETH' then 'OUT' end as direction,
	count(tx_hash) as tx_num, sum(iff(symbol_in = 'WETH', amount_in_usd, amount_out_usd)) as total_amount_usd
from info
group by date, direction
order by date


with info as (
	select date(BLOCK_TIMESTAMP) as date, platform, amount_in_usd, amount_out_usd, symbol_in, symbol_out, token_in, token_out, tx_hash
	from ethereum.core.ez_dex_swaps
	where token_in = lower('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
		or token_out = lower('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
		and (amount_in_usd > 0 and amount_out_usd > 0)
)
select date, platform, count(tx_hash) as tx_num, sum(amount_in_usd) as total_amount_usd
from info
where token_in = lower('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
group by date, platform
order by date






-- Project 3
-- We will explore different liquidity pools on DEXs. Analyze amount changes of liquidity pools on Uniswap.
-- a. Find liquidity pools on Uniswap. 
   -- Show a table with times when balances are recorded (balance_time), pool name, platform name, two token IDs for the pairs, and amount in USD 
   -- (note the table "flipside_prod_db.ethereum.dex_liquidity_pools" is depreciating. If no access, use the table "ethereum.core.dim_dex_liquidity_pools").
-- b. Find amount changes of the liquidity pools over seven days 
   -- (note recent ERC 20 balances may not have recorded by Flipside meaning there may not be today's or even yesterday's balance data. 
   -- Pick any two-time points with a week difference). 
   -- Create two visualizations showing the top 10 LPs that have been increased and the top 10 that have been decreased. 
   -- Which ones are the most increased and decreased LP?
-- c. Find daily amounts of the most increased and decreased LPs over a week. Create two visualizations showing daily amounts of the two LPs.


select balance_date, pool_name, platform, token0, token1, amount_usd
from flipside_prod_db.ethereum.dex_liquidity_pools l
join flipside_prod_db.ethereum.erc20_balances e on e.user_address = l.pool_address
where platform ilike '%uniswap%'
	and amount_usd > 0

with minus_seven as (
select max(balance_date), pool_name, sum(amount_usd) as ave_amount_usd
from flipside_prod_db.ethereum.dex_liquidity_pools l
join flipside_prod_db.ethereum.erc20_balances e on e.user_address = l.pool_address -- pool address: dex address
where platform ilike '%uniswap%'
	and amount_usd > 0
	and balance_date = current_date-9
group by pool_name
),
minus_zero as (
select max(balance_date), pool_name, sum(amount_usd) as ave_amount_usd
from flipside_prod_db.ethereum.dex_liquidity_pools l
join flipside_prod_db.ethereum.erc20_balances e on e.user_address = l.pool_address
where platform ilike '%uniswap%'
	and amount_usd > 0
	and balance_date = current_date-2
group by pool_name
)
select s.pool_name, (z.ave_amount_usd - s.ave_amount_usd) as amount_change
from minus_seven s
join minus_zero z on z.pool_name = s.pool_name
order by amount_change 
limit 10

with minus_seven as (
select max(balance_date), pool_name, sum(amount_usd) as ave_amount_usd
from flipside_prod_db.ethereum.dex_liquidity_pools l
join flipside_prod_db.ethereum.erc20_balances e on e.user_address = l.pool_address
where platform ilike '%uniswap%'
	and amount_usd > 0
	and balance_date = current_date-9
group by pool_name
),
minus_zero as (
select max(balance_date), pool_name, sum(amount_usd) as ave_amount_usd
from flipside_prod_db.ethereum.dex_liquidity_pools l
join flipside_prod_db.ethereum.erc20_balances e on e.user_address = l.pool_address
where platform ilike '%uniswap%'
	and amount_usd > 0
	and balance_date = current_date-2
group by pool_name
)
select s.pool_name, (z.ave_amount_usd - s.ave_amount_usd) as amount_change
from minus_seven s
join minus_zero z on z.pool_name = s.pool_name
order by amount_change desc
limit 10

select balance_date, pool_name, sum(amount_usd)
from flipside_prod_db.ethereum.dex_liquidity_pools l
join flipside_prod_db.ethereum.erc20_balances e on e.user_address = l.pool_address
where platform ilike '%uniswap%'
	and amount_usd > 0
  	and balance_date >= current_date -9
  	and pool_name = 'SAITAMA-WETH UNI-V2 LP'
group by balance_date, pool_name
order by balance_date





-- Project 4
-- We will analyze deposit activities by ETH holders. Analyze ETH deposits into DEX, DeFi, and Dapp platforms.
-- a. Find how much ETHs have been deposited since May 1st, 2022. 
   -- Show a table with time stamps, names of platforms, labels of whether DEX, DeFi, or Dapp, and amounts in ETH 
   -- (since analyzing external ETH flows from the outside, make sure not to include internal transfers like transfers within DEXs, DeFis, or Dapps).
-- b. Find daily deposit amounts. Create a visualization of daily deposit volumes in ETH separated by DEX, DeFi, and Dapp. 
   -- Is the total deposit amount increasing or decreasing? Which one of the three is popular in terms of the amount?
-- c. Now, investigate deposit amounts in DEX platforms. Create a visualization of daily deposit volumes in ETH by DEX platforms 
   -- (again, only deposits from the outside of DEXs only, e.g., CEX → DEX, Dapp → DEX). 
   -- Is the total deposit amount increasing or decreasing? Which platform is the most popular?


select date(block_timestamp) as date, label, label_type, amount
from ethereum.core.dim_labels 
	join ethereum.core.ez_eth_transfers on eth_to_address = address -- address:platform address, eth_to_address: address that ETH is deposited.
where date >= '2022-05-01'
	and ((label_type = 'dex' and eth_from_address not in (select address from ethereum.core.dim_labels where label_type = 'dex'))
	or (label_type = 'defi' and eth_from_address not in (select address from ethereum.core.dim_labels where label_type = 'defi'))
	or (label_type = 'dapp' and eth_from_address not in (select address from ethereum.core.dim_labels where label_type = 'dapp')))
-- For example "label_type = 'cex'" may include ETH deposits from one CEX to another CEX
  
select date(block_timestamp) as date, label_type, sum(amount) as amount
from ethereum.core.dim_labels 
	join ethereum.core.ez_eth_transfers on eth_to_address = address
where date >= '2022-05-01'
	and ((label_type = 'dex' and eth_from_address not in (select address from ethereum.core.dim_labels where label_type = 'dex'))
	or (label_type = 'defi' and eth_from_address not in (select address from ethereum.core.dim_labels where label_type = 'defi'))
	or (label_type = 'dapp' and eth_from_address not in (select address from ethereum.core.dim_labels where label_type = 'dapp')))
group by date, label_type
order by date 
  
select date(block_timestamp) as date, label, label_type, sum(amount) as amount
from ethereum.core.dim_labels 
	join ethereum.core.ez_eth_transfers on eth_to_address = address
where label_type = 'dex'
	and eth_from_address not in (select address from ethereum.core.dim_labels where label_type = 'dex')
	and date >= '2022-05-01'
group by date, label, label_type
order by date 






-- Project 5
-- We will discover suggested proposals and votes in DAOs. Find suggested proposals and corresponding votes on the GovernorAlpha DAO.
-- a. Find what proposals have been proposed. 
   -- Show a table with time stamps, proposers, proposal IDs, and descriptions of proposals 
   -- (use '0xb3a87172f555ae2a2ab79be60b336d2f7d0187f0' for the contract address) (hint: event_name='ProposalCreated').
-- b. Find whether voters agree or disagree and the number of votes. 
   -- Show a table with proposal IDs, agree/disagree, and number of votes (hint: event_name='VoteCast').
-- c. Combine the two tables such that show a table with proposal IDs, proposal descriptions, number of fors and againsts. 
   -- Then create a visualization showing the number of fors and againsts by proposal IDs. Explain the visualization.


select date(block_timestamp) as date, event_inputs:proposer as proposer, event_inputs:id as id, event_inputs:description as content
from ethereum.core.fact_event_logs 
where contract_address = '0xb3a87172f555ae2a2ab79be60b336d2f7d0187f0'
	and event_name='ProposalCreated'
order by id

select event_inputs:proposalId as id, event_inputs:support as result, event_inputs:votes as num_vote
from ethereum.core.fact_event_logs 
where contract_address = '0xb3a87172f555ae2a2ab79be60b336d2f7d0187f0'
	and event_name='VoteCast'
order by id

with proposal as (
select date(block_timestamp) as date, event_inputs:proposer as proposer, event_inputs:id as id, event_inputs:description as content
from ethereum.core.fact_event_logs 
where contract_address = '0xb3a87172f555ae2a2ab79be60b336d2f7d0187f0'
	and event_name='ProposalCreated'
order by id
),
vote as(
select event_inputs:proposalId as id, event_inputs:support as result, event_inputs:votes as num_vote
from ethereum.core.fact_event_logs 
where contract_address = '0xb3a87172f555ae2a2ab79be60b336d2f7d0187f0'
	and event_name='VoteCast'
order by id
)
select p.id as proposal_id, p.content, 
	sum(case when result = true then num_vote end) as agree,
	sum(case when result = false then num_vote end) as disagree
from proposal p
	join vote v on p.id = v.id
group by proposal_id, p.content
order by proposal_id
