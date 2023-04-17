-- NFT-related SQL-based projects for graduate-level blockchain analytics course
-- Created by kiyunlee on 05/15/2022


-- Description
-- 1. These are 5 NFT-related projects that I (kiyunlee) built on May, 2022.
-- 2. In terms of timeline of the course, students need to complete at the 5th week of the course.
-- 3. Students should select one project, build and submit an interactive SQL dashboard on Flipside Crypto or Dune.
-- 4. Due to reuse of the projects with modifications over the course, here I show simpler versions of questionnaires and solutions.





-- Project 1
-- Investigate the Solana-based NFT platform, Magic Eden. 
-- a. What projects currently exist on Magic Eden, and what are their total sale volumes?
   -- Show a table with the top 10 projects from highest to lowest volumes. When are the first dates they were created?
-- b. Find daily sale volumes of the ten projects. Create a visualization showing sale volumes of the collections since their creations.
-- c. During which periods, were Okay Bear collections significantly outsold compared to others? 


select contract_name as collection, sum(sales_amount) as total_sale_amount, min(created_at_timestamp) as creation_date
from solana.fact_nft_sales s
  join solana.dim_nft_metadata m on s.mint = m.mint -- minting addresses from both tables should be the same
where marketplace ilike 'magic%' -- SOL-based NFT marketplace
group by collection
order by total_sale_amount desc
  limit 10

select left(block_timestamp,10) as sale_date, contract_name as collection, 
  sum(sales_amount) as daily_sale_amount
from solana.fact_nft_sales s
  join solana.dim_nft_metadata m on s.mint = m.mint
where marketplace ilike 'magic%'
	and collection in ('Okay Bears','DeGods','Trippin%','Cets On Creck','Primates','Degen Apes','Blocksmith Labs','Communi3: Mad Scientists','Just Ape','TombStoned High Society')
group by sale_date, collection 
order by sale_date 
  




-- Project 2
-- Find sale volume and profit changes of NFT collections on the Ethereum-based NFT platform, OpenSea. 
-- a. Find the five most popular projects on OpenSea. Show a table with project names, and prices in ETH and in USD. 
-- b. What projects have shown the greatest increase and decrease in volume? What do trends look like?
   -- Create a visualization showing sale volumes in ETH over the past 12 months for the five projects.
-- c. How do the daily profit changes of the projects look like? How do profits correlate with sales volumes?
   -- Profit can be simply calculated by subtracting from platform fee from the sale price. 
   -- Create a visualization showing daily profits in ETH over the past 12 months for the five projects. 


select m.project_name as project, sum(price) as total_price, sum(price_usd) as total_price_USD
	from ethereum.nft_metadata m 
  join ethereum.nft_events n on m.contract_address = n.contract_address 
  where event_platform ilike 'opensea%' -- ETH-based NFT platform
  	and event_type ilike '%sale%'
  group by project
  order by total_price desc
  limit 5

select left(block_timestamp,10) as sale_date, m.project_name as project,
  sum(price) as total_daily_price, sum(price_usd) as total_daily_price_USD,
  sum(platform_fee) as total_platform_fee, total_daily_price-total_platform_fee as total_profit
  from ethereum.nft_metadata m 
  join ethereum.nft_events n on m.contract_address = n.contract_address 
  where event_platform ilike 'opensea%'
  	and event_type ilike '%sale%'
  	and m.project_name in ('sandboxs_land','art_blocks','raribles_nfts','bored_ape_yacht_club','zora')
  	and block_timestamp >= CURRENT_TIMESTAMP - interval '1 year'
  group by sale_date,project
  order by sale_date

  



-- Project 3
-- The MAYC is a way to reward BAYC holders with an entirely new NFT. Explore relationships between BAYC and MAYC.
-- a. Show daily transaction number and sale volume in ETH of BAYC and MAYC 
   -- (hint: "boredapeyachtclub" and "BoredApeYachtClub" are the same, therefore find projects called by both names). Show a table.
-- b. How is the number of daily transactions of BAYC and MAYC correlated? How do you see this trend continuing? Show a visualization. 
-- c. What about the daily sale volume in ETH? How do you see this trend continuing? Show a visualization. 


with info as (
	select left(block_timestamp,10) as sale_date, project_name, 
		count(tx_id) as transaction_number, sum(price) as sale_volume
	from ethereum.nft_events
	where (project_name ilike 'boredapeyachtclub%'
  		or project_name ilike 'mutantapeyachtclub%')
  		and price > 0  -- avoid any null data
	group by sale_date, project_name
	order by sale_date
)
select sale_date,
	case
    	when project_name = 'boredapeyachtclub' or project_name = 'BoredApeYachtClub' then 'BAYC'
    	when project_name = 'mutantapeyachtclub' or project_name = 'MutantApeYachtClub' then 'MAYC'
		end as NFT_name,
	sum(transaction_number) as daily_transaction_number, sum(sale_volume) as daily_sale_volume
from info
group by sale_date, NFT_name
order by sale_date
  



-- Project 4
-- Compare the resale and mint price of Solana NFT collections. 
-- a. Find total sale price, total mint price, average sale price, and average mint price by collection names. Show a table.
-- b. How are sale prices related to mint prices? Show a visualization of average sale and mint price based on NFT collections.  
-- c. How are profits correlated to the number of sales? Calculate profits from each NFT collection and show a visualization.


select	
	contract_name as collection,
	sum(sales_amount) as total_sale_amount,
	sum(mint_price) as total_mint_price,
	avg(sales_amount) as ave_sale_amount,
	avg(mint_price) as ave_mint_price
from solana.fact_nft_sales s
  join solana.dim_nft_metadata m on s.mint = m.mint
  join solana.fact_nft_mints n on s.mint = n.mint
group by collection





-- Project 5
-- Find NFT traders who gain and lose. 
-- a. Let's find buying time, buying price, selling time, and selling price in ETH of NFT transactions. 
   -- Show a table with buying time, buying price, first owner's address (seller), second owner's address (buyer), selling time, selling price, second owner's address (seller), and third owner's address (buyer).
   -- Make sure buying time is earlier than selling time.
-- b. Now let's find holding days of NFTs and net gain/loss. Show a table with holding days and average net gains/losses. 
-- c. When do you gain profits the most? What about losses? Show a visualization of net gains/losses by holding days. Explain the trend.


with info as (
select left(block_timestamp,10) as buying_time, PROJECT_NAME, SELLER_ADDRESS, BUYER_ADDRESS, price
from ethereum_core.ez_nft_sales
)
select buying_time, i.price as buying_price,
	i.seller_address as owner1, i.buyer_address as owner2a, 
  	left(s.block_timestamp,10) as selling_time, s.price as selling_price,
	s.seller_address as owner2b, s.buyer_address as owner3,
from ethereum_core.ez_nft_sales s  
	join info i on s.seller_address=i.buyer_address
where buying_time<selling_time -- The second sale date is later than the first sale date


with info as (
select left(block_timestamp,10) as buying_time, PROJECT_NAME, SELLER_ADDRESS, BUYER_ADDRESS, price
from ethereum_core.ez_nft_sales
),
info2 as (
select buying_time, i.price as buying_price,
	i.seller_address as owner1, i.buyer_address as owner2a, 
  	left(s.block_timestamp,10) as selling_time, s.price as selling_price,
	s.seller_address as owner2b, s.buyer_address as owner3,
	DATEDIFF(day,buying_time,selling_time) as holding_days, selling_price-buying_price as net_gain
from ethereum_core.ez_nft_sales s  
	join info i on s.seller_address=i.buyer_address
where buying_time<selling_time  -- The second sale date is later than the first sale date
)
select holding_days, avg(net_gain)
from info2
group by holding_days
order by holding_days

