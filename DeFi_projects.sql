-- Decentralized finance (DeFi)-related SQL-based projects for graduate-level blockchain analytics course
-- Created by kiyunlee on 05/26/2022


-- Description
-- 1. These are 5 DeFi-related projects that I (kiyunlee) built on May, 2022.
-- 2. In terms of timeline of the course, students need to complete at the 6th week of the course.
-- 3. Students should select one project, build and submit an interactive SQL dashboard on Flipside Crypto or Dune.
-- 4. Due to reuse of the projects with modifications over the course, here I show simpler versions of questionnaires and solutions.



-- Project 1
-- StepN is a move-to-earn game on SOL and users can earn GST layer 2 tokens. 
-- We would like to know how StepN is getting popular. Investigate GST swap activity and daily user activity.
-- a. Analyze successful swap activity of GST tokens that are sent and received separately (note succeeded = 'True').
   -- Show a table with time stamps, labels of whether GST is sent or received, sender addresses, receiver addresses, and amounts.  
-- b. How many GST tokens are sent and received daily? Create a visualization showing daily GST token amounts. 
-- c. Let's look at total GST swap activity.
   -- Create a visualization showing the daily amounts and address numbers regardless of sender and receiver. How do they correlate? 


select left(s.block_timestamp,10) as date, s.tx_id as tx_id, 
	case 
		when s.swap_from_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' then 'Sender'  -- GST token ID. Can be found on SOLSCAN
		when s.swap_to_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' then 'Receiver' end as "sender/receiver",
	case 
		when s.swap_from_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' then s.swap_from_amount
		when s.swap_to_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' then swap_to_amount end as amount,
	s.swap_from_mint, s.swap_to_mint, t.tx_from, t.tx_to
from solana.core.fact_swaps s
	join solana.core.fact_transfers t on s.tx_id=t.tx_id
where (s.swap_from_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' or s.swap_to_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB')
	and succeeded = 'True'
order by date

  
with info as (
	select left(s.block_timestamp,10) as date, s.tx_id as tx_id, 
		case 
			when s.swap_from_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' then 'Sender'
			when s.swap_to_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' then 'Receiver' end as "sender/receiver",
		case 
			when s.swap_from_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' then s.swap_from_amount
			when s.swap_to_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' then swap_to_amount end as amount,
		s.swap_from_mint, s.swap_to_mint, t.tx_from, t.tx_to
	from solana.core.fact_swaps s
  		join solana.core.fact_transfers t on s.tx_id=t.tx_id
	where (s.swap_from_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB' or s.swap_to_mint = 'AFbX8oGjGpmVFywbVouvhQSRmiW2aR1mohfahi4Y2AdB')
		and succeeded = 'True'
	order by date
)
select date, "sender/receiver", sum(amount), avg(amount), count(tx_id) as address_num
from info
group by date, "sender/receiver"
order by date





-- Project 2
-- Some swap activities in DEXs involve stablecoins. Find which tokens are used to swap to get USDC or USDT. 
-- Analyze trading pairs to get USDC or USDT on ORCA, DEX on the SOL network.
-- a. Analyze trading pairs to get USDC or USDT (token x-USDC and token x-USDT pairs) on ORCA. 
   -- Show a table with time stamps, sender addresses, receiver addresses, labels of trading pair (e.g., usd coin to raydium, raydium to USDT),
   -- and amounts of USDC or USDT in the pairs (note succeeded = 'True').  
-- b. How do the daily trading amounts look like? Create a visualization showing the daily amounts by trading pairs.
-- c. Now, modify the code to find the top 10 trading pairs in amount for each day (hint: ROW_NUMBER or RANK will be useful). 
   -- Create a visualization showing the daily amount by the top 10 trading pairs. 


with info as (
	select left(block_timestamp,10) as date, swap_from_mint, swap_to_mint,
		sum(iff(SWAP_FROM_MINT = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' or SWAP_FROM_MINT = 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB', swap_from_amount, swap_to_amount)) as amount_USD -- USDC token ID. Can be found on SOLSCAN
	from solana.core.fact_swaps
	where swap_program = 'orca'
		and (SWAP_FROM_MINT = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' or SWAP_FROM_MINT = 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB' or 
			SWAP_to_MINT = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' or SWAP_to_MINT = 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB')
		and succeeded = 'True'
	group by date, swap_from_mint, swap_to_mint
)
select date, swap_from_mint, swap_to_mint, amount_USD, concat(l1.label,' to ' ,l2.label) as "PAIR"
from info
	join solana.core.dim_labels as l1 on l1.address = info.SWAP_FROM_MINT
	join solana.core.dim_labels as l2 on l2.address = info.SWAP_TO_MINT
order by date


  
with info as (
	select left(block_timestamp,10) as date, swap_from_mint, swap_to_mint,
		sum(iff(SWAP_FROM_MINT = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' or SWAP_FROM_MINT = 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB', swap_from_amount, swap_to_amount)) as amount_USD
	from solana.core.fact_swaps
	where swap_program = 'orca'
		and (SWAP_FROM_MINT = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' or SWAP_FROM_MINT = 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB' or 
			SWAP_to_MINT = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' or SWAP_to_MINT = 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB')
		and succeeded = 'True'
	group by date, swap_from_mint, swap_to_mint
),
top_10 as (
	select row_number() over (partition by date order by amount_USD DESC) as "RANK", date,
		swap_from_mint, swap_to_mint, amount_USD, concat(l1.label,' to ' ,l2.label) as "PAIR"
	from info
		join solana.core.dim_labels as l1 on l1.address = info.SWAP_FROM_MINT
		join solana.core.dim_labels as l2 on l2.address = info.SWAP_TO_MINT
	order by date, "RANK"
)
select *
from top_10
where "RANK"<11






-- Project 3
-- Solana is a drastically growing network and is known to be an Ethereum killer. 
-- Solana also has many platforms on top of the network. Analyze user activity of popular platforms on the SOL network. 
-- a. Find successful user activities of Saber, Orca, and Mango market since April 2022 which are DEX platforms on SOL network.
   -- Show a table with time stamps, labels of which platform, signers, and transaction IDs (note succeeded = 'True').
-- b. Analyze the activities. Create visualizations showing a daily number of addresses and transactions by each platform. 
-- c. On average, how many transactions are made by users? Create a visualization showing the daily average number of transactions by each platform.


with info as (
	select left(block_timestamp,10) as date, 
		case 
			when INSTRUCTIONS[0]:programId = 'SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ' then 'Saber stable swap'
			when INSTRUCTIONS[0]:programId = '9W959DqEETiGZocYWCQPaJ6sBmUzgfxXfqGeTEdp3aQP' then 'Orca token swap v2'
			when INSTRUCTIONS[0]:programId = 'mv3ekLzLbnVPNxjSKvqBpU3ZeZXPQdEC3bp5MDEBG68' then 'Mango Market v3' end as programs,
		signers, tx_id
	from solana.core.fact_transactions
	where INSTRUCTIONS[0]:programId in ('SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ',
		'9W959DqEETiGZocYWCQPaJ6sBmUzgfxXfqGeTEdp3aQP', 'mv3ekLzLbnVPNxjSKvqBpU3ZeZXPQdEC3bp5MDEBG68')
		and SUCCEEDED = true
		and date >= '2022-04-01'
	order by date
)
select date, programs, count(distinct signers[0]) as address_num, count(distinct tx_id) as transaction_num, transaction_num/address_num as ave_transaction_num
from info
group by date, programs
order by date





-- Project 4
-- We will analyze another stablecoin on SOL networks, USDH. 
-- Track USDH activities to find the initial tokens before swaps, and analyze the activities by programs and swap pairs.
-- a. Using the solana.core.fact_swaps table, show a table with time stamps, swap programs, transaction IDs, swap amounts in original tokens,
   -- swap amounts in USDH, and labels of which token is swapped to USDH (for example, if swap from WBTC to USDC, then the label would be like "WBTC to USDC").  
-- b. Analyze swap volumes in USDH and transaction numbers by programs. Create visualizations of daily swap volumes and transaction numbers by programs. 
-- c. Find the top five swap pairs by swap volumes. Show a table with labels, total swap volumes, and total transaction numbers. 
   -- Then, create visualizations of daily swap volumes and transaction numbers by swap pairs.  


with info as (
select left(block_timestamp,10) as date, swap_program, swap_from_amount, swap_to_amount, tx_id, concat(label,' to ' ,'USDH') as "LABEL"
from solana.core.fact_swaps 
	join solana.core.dim_labels on solana.core.dim_labels.address = solana.core.fact_swaps.swap_from_mint
where swap_to_mint = 'USDH1SM1ojwWUga67PGrgFWUHibbjqMvuMaDkRJTgkX'
	and (swap_from_amount>0 and swap_to_amount>0)
)
select date, swap_program, sum(swap_to_amount) as total_swap_amount_USDH, count(tx_id) as transaction_num
from info
group by date, swap_program

  
with info as (
select left(block_timestamp,10) as date, swap_program, swap_from_amount, swap_to_amount, tx_id, concat(label,' to ' ,'USDH') as "LABEL"
from solana.core.fact_swaps 
	join solana.core.dim_labels on solana.core.dim_labels.address = solana.core.fact_swaps.swap_from_mint
where swap_to_mint = 'USDH1SM1ojwWUga67PGrgFWUHibbjqMvuMaDkRJTgkX'
	and (swap_from_amount>0 and swap_to_amount>0)
)
select label, sum(swap_to_amount) as total_swap_amount_USDH, count(tx_id) as transaction_num
from info
group by label
order by total_swap_amount_USDH desc


with info as (
select left(block_timestamp,10) as date, swap_program, swap_from_amount, swap_to_amount, tx_id, concat(label,' to ' ,'USDH') as "LABEL"
from solana.core.fact_swaps 
	join solana.core.dim_labels on solana.core.dim_labels.address = solana.core.fact_swaps.swap_from_mint
where swap_to_mint = 'USDH1SM1ojwWUga67PGrgFWUHibbjqMvuMaDkRJTgkX'
	and (swap_from_amount>0 and swap_to_amount>0)
)
select date, label, sum(swap_to_amount) as total_swap_amount_USDH, count(tx_id) as transaction_num
from info
where label in ('usd coin to USDH','usdt to USDH','wormhole to USDH','wrapped sol to USDH','lido staked sol to USDH')
group by date, label





-- Project 5
-- For Solana holders, they can stake SOL into SOL networks or DeFi platforms. Let's analyze SOL staking into DeFi platforms.
-- Analyze SOL addresses involving SOL staking to DeFi platforms for the past month.
-- a. Find SOL stakers' addresses and DeFi platforms they use for the past month. 
   -- First, we need to identify stakers' addresses using the staking_lp_actions table. 
   -- Then show a table with time stamps, stakers' addresses, and DeFi platforms
   -- (Be aware not to include direct staking activities into SOL networks. Please refer to the sample dashboard). 
-- b. Find the number of stakers and the average number of platforms that a staker has used. 
   -- Create a visualization of the daily number of stakers' addresses regardless of platforms.
   -- Also, what is the average number of platforms a staker has used for the past month?  
-- c. Analyze DeFi platforms. Create a pie chart showing the proportions of how much each platform is used. Which platform is the most popular? 


with staker_address as (
	select signers[0] as address -- staker's address
	from solana.core.fact_staking_lp_actions
	where event_type = 'delegate' -- staking activity
	group by address
),
defi_info as (
select left(block_timestamp,10) as "DATE", t.signers[0] as staker, l.label as DeFi_platform
from solana.core.fact_transactions t
	join solana.core.dim_labels l on t.instructions[0]:programId = l.address
where t.signers[0] in (select * from staker_address)
	and l.label != 'solana' -- this means staking directly on SOL networks, not DEXs
	and (DATEDIFF(day, "DATE", current_date ) >= 0 and DATEDIFF(day, "DATE", current_date ) <= 60)
	and t.succeeded = TRUE
order by "DATE"
)
select "DATE", count(distinct staker) as staker_num
from defi_info
group by "DATE"
order by "DATE"



with staker_address as (
	select signers[0] as address
	from solana.core.fact_staking_lp_actions
	where event_type = 'delegate'
	group by address
),
defi_info as (
select left(block_timestamp,10) as "DATE", t.signers[0] as staker, l.label as DeFi_platform
from solana.core.fact_transactions t
	join solana.core.dim_labels l on t.instructions[0]:programId = l.address
where t.signers[0] in (select * from staker_address)
	and l.label != 'solana'
	and (DATEDIFF(day, "DATE", current_date ) >= 0 and DATEDIFF(day, "DATE", current_date ) <= 60)
	and t.succeeded = TRUE
order by "DATE"
)
select count(DeFi_platform) as platform_num, count(distinct staker) as staker_num, platform_num/staker_num
from defi_info



with staker_address as (
	select signers[0] as address
	from solana.core.fact_staking_lp_actions
	where event_type = 'delegate'
	group by address
),
defi_info as (
select left(block_timestamp,10) as "DATE", t.signers[0] as staker, l.label as DeFi_platform
from solana.core.fact_transactions t
	join solana.core.dim_labels l on t.instructions[0]:programId = l.address
where t.signers[0] in (select * from staker_address)
	and l.label != 'solana'
	and (DATEDIFF(day, "DATE", current_date ) >= 0 and DATEDIFF(day, "DATE", current_date ) <= 60)
	and t.succeeded = TRUE
order by "DATE"
)
select DeFi_platform, count(DeFi_platform) as platform_num
from defi_info
group by DeFi_platform