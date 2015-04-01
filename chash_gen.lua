module("chash_gen", package.seeall);

local MMC_CONSISTENT_BUCKETS = 65536

local function hash_fn(key)
	local md5 = ngx.md5_bin(key) --nginx only
	return ngx.crc32_long(md5) --nginx only
end

--in-place quicksort
local function quicksort(t, start, endi)
	start, endi = start or 1, endi or #t
	--partition w.r.t. first element
	if(endi - start < 2) then return t end
	local pivot = start
	for i = start + 1, endi do
		if t[i][2] < t[pivot][2] then
			local temp = t[pivot + 1]
			t[pivot + 1] = t[pivot]
			if(i == pivot + 1) then
				t[pivot] = temp
			else
				t[pivot] = t[i]
				t[i] = temp
			end
			pivot = pivot + 1
		end
	end
	t = quicksort(t, start, pivot - 1)
	return quicksort(t, pivot + 1, endi)
end

local function chash_find(hash, point)
	local mid, lo, hi = 1, 1, #(hash.continuum)
	while 1 do
		if point <= hash.continuum[lo][2] or point > hash.continuum[hi][2] then
			return hash.continuum[lo]
		end

		mid = math.floor(lo + (hi-lo)/2)
		if point <= hash.continuum[mid][2] and point > (mid and hash.continuum[mid-1][2] or 0) then
			return hash.continuum[mid]
		end

		if hash.continuum[mid][2] < point then
			lo = mid + 1
		else
			hi = mid - 1
		end
	end
end

local function chash_init(hash)
	local n = #(hash.hash_peers)

	local ppn = math.floor(MMC_CONSISTENT_BUCKETS / n)
	if ppn == 0 then
		ppn = 1
	end

	local C = {}
	for i,peer in ipairs(hash.hash_peers) do
		for k=1, math.floor(ppn * peer[1]) do
			local hash_data = peer[2] .. "-"..tostring(math.floor(k - 1))
			table.insert(C, {peer[2], hash_fn(hash_data)})
		end
	end

	hash.continuum = quicksort(C, 1, #C)

	local step = math.floor(0xFFFFFFFF / MMC_CONSISTENT_BUCKETS)

	hash.buckets = {}
	for i=1, MMC_CONSISTENT_BUCKETS do
		table.insert(hash.buckets, i, chash_find(hash, math.floor(step * (i - 1))))
	end

	hash.initialized = true
end

local function get_upstream(hash, key)
	if not initialized then
		chash_init(hash)
	end

	local point = math.floor(ngx.crc32_long(key)) --nginx only

	local tries = #(hash.hash_peers)
	point = point + (89 * tries)

	return hash.buckets[point % MMC_CONSISTENT_BUCKETS][1]
end

local function add_upstream(hash, upstream, weigth)
	hash.initialized = false

	weight = weight or 1
	table.insert(hash.hash_peers, {weight, upstream})
end

function create_hash()
    return {
        initialized = false,
        hash_peers = {}, 
        continuum = {},
        buckets = {},
        get_upstream = get_upstream,
        add_upstream = add_upstream
    }
end


